#!/bin/bash

# ensure running with root privileges
if [ "$(id -u)" != "0" ]; then
    echo "User does not have root permissions, attempting to run the installer with sudo:"
    if ! exec sudo "$0" "$@"; then
        echo "Unable to run as sudo, please run the installer with a user in the sudoers group."
        exit 1
    fi
fi

# Get dynamic config info from user if config.json doesn't exist
if [ ! -e "${BASH_SOURCE%/*}"/config.json ]; then
    read -p "Please input your linux server's DNS:" -r
    if [ -z "$REPLY" ]; then
        echo "No name given, exiting install."
        exit 1
    elif [ -e "$REPLY" ]; then
        echo "Setting DNS to $REPLY"
        SERVER_DNS=$REPLY
    else
        echo "ERROR: something went wrong..."
        exit 1
    fi
    read -p "Please input your linux server's db username:" -r
    if [ -z "$REPLY" ]; then
        echo "No username given, exiting install."
        exit 1
    elif [ -e "$REPLY" ]; then
        DB_USER=$REPLY
    else
        echo "ERROR: something went wrong..."
        exit 1
    fi
    read -s -p "Please input your linux server's db password:" -r
    if [ -z "$REPLY" ]; then
        echo "No password given, exiting install."
        exit 1
    elif [ -e "$REPLY" ]; then
        DB_PWD=$REPLY
    else
        echo "ERROR: something went wrong..."
        exit 1
    fi
    read -p "Please input your linux server's db name:" -r
    if [ -z "$REPLY" ]; then
        echo "No name given, exiting install."
        exit 1
    elif [ -e "$REPLY" ]; then
        DB_NAME=$REPLY
    else
        echo "ERROR: something went wrong..."
        exit 1
    fi
    read -p "Please input your youtube api key:" -r
    if [ -z "$REPLY" ]; then
        echo "No name given, exiting install."
        exit 1
    elif [ -e "$REPLY" ]; then
        YOUTUBE_API_KEY=$REPLY
    else
        echo "ERROR: something went wrong..."
        exit 1
    fi
    read -p "Please input your chromecast's name:" -r
    if [ -z "$REPLY" ]; then
        echo "No name given, exiting install."
        exit 1
    elif [ -e "$REPLY" ]; then
        CHROMECAST_NAME=$REPLY
    else
        echo "ERROR: something went wrong..."
        exit 1
    fi
fi

#--------------------------------#
# Use this to set up your server #
#--------------------------------#
if [[ "$(uname)" == 'Linux' ]]; then
    if grep -q "ubuntu" /proc/version; then
        apt-get -qq update
        apt-get -qq upgrade
        apt-get -qq install curl apache2 mysql-server zip
    elif grep -q "Red Hat" /proc/version; then
        yum install -y -d0 -e0 curl httpd mysql zip
    else
        echo "Platform currently not supported. Sorry!"
        exit 1
    fi
elif [[ "$(uname)" == 'FreeBSD' ]]; then
    # something like this:
    # pkg install apache24 mysql56-server zip
    echo "Platform currently not supported. Sorry!"
    exit 1
elif [[ "$(uname)" == 'Darwin' ]]; then
    if hash xcode-select 2>/dev/null; then
        if hash mysql 2>/dev/null; then
            echo "mysql is already installed."
        else
            echo "downloading mysql..."
            curl -L https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.16-osx10.11-x86_64.dmg -o /tmp/mysql.dmg
            echo "download complete. installing..."
            hdiutil attach /tmp/mysql.dmg
            installer -pkg /Volumes/mysql-5.7.16-osx10.11-x86_64/mysql-5.7.16-osx10.11-x86_64.pkg -target /
            echo export PATH=/usr/local/mysql/bin:$PATH >> /etc/bashrc
            source /etc/bashrc
        fi
    else
        echo "xcode isn't installed. Please install xcode and try again."
        exit 1
    fi
fi

# Install youtube-dl
curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl
chmod a+rx /usr/local/bin/youtube-dl

# Install python pip
curl https://bootstrap.pypa.io/get-pip.py
python get-pip.py

# Install pymysql, pychromecast, and awscli
pip install pymysql
pip install pychromecast
pip install awscli

#------------------------------#
# Set up upload dir for Lambda #
#------------------------------#

# remove any previous upload dir
rm -rf "${BASH_SOURCE%/*}"/upload

cd "${BASH_SOURCE%/*}" || exit 1
mkdir -p upload/dist
# Add pymysql and bs4
pip install pymysql -t ./upload/dist
pip install beautifulsoup4 -t ./upload/dist
# Copy over index
cp -r index.py upload/index.py
cd ~- || exit 1

# Create config based on installer's input
if [ -e "${BASH_SOURCE%/*}"/upload/config.json ]; then
    rm -f "${BASH_SOURCE%/*}"/upload/config.json
fi
if [ ! -e "${BASH_SOURCE%/*}"/config.json ]; then
cat << EOF >> "${BASH_SOURCE%/*}"/config.json
{
    "server_dns": "$SERVER_DNS" ,
    "db_user":"$DB_USER",
    "db_pwd": "$DB_PWD",
    "db_name": "$DB_NAME",
    "youtube_api_key":"$YOUTUBE_API_KEY",
    "chromecast_name":"$CHROMECAST_NAME"
}
EOF
fi

# copy over the config file for local.py to access/use as well
cp -r "${BASH_SOURCE%/*}"/config.json "${BASH_SOURCE%/*}"/upload/config.json

# Create zip to send to Lambdas
zip -r alexa-chromecast-skill.zip upload

aws lambda update-function-code --function-name AlexaChromecastSkill --zip-file fileb://alexa-chromecast-skill.zip

#On AWS Lambda, Create A new Skill with Basic Execution and The Alexa Skills Kit Event Source with Python 2.7 as the interpreter.
#- **IMPORTANT: Make sure that index is the event, lambda_handler is the handler, and Python is the Interpreter**
# Use intentSchema.json and sample-utterances.txt to set your Intents and Sample Utterances.

# Run local.py
python local.py
