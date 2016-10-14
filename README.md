Alexa Chromecast Skill
===

This repo sets up an alexa skill to allow Amazon Alexa to control a Google Chromecast.

# Current Features:

## Play, Pause, and Resume Youtube Videos (Based on Sample Utterances)

__Play__ Youtube videos by saying "Alexa, ask ChromeCast to play Jontron Home Improvement".
Alexa will send the video URL to your Chromecast and start playing the youtube video.

__Pause__ videos by saying "Alexa, ask ChromeCast to pause".

__Resume__ videos by saying "Alexa, ask ChromeCast to resume".

## Changing the Volume
You can change the volume of the chromecast in percentage increments by saying "Alexa ask ChromeCast to change the volume to 50".

# Requirements
  - a \*nix device (tested with ubuntu, centos, & osx. working on bsd support.)
  - bash needs to be installed to run the installer script.

# Installation
1. On your \*nix device, clone this repository and run the installer:
```
git clone git@github.com/kgrubb/alexa-chromecast-skill && cd alexa-chromecast-skill
sudo bash install.sh
```
2. If you need to change your config, you can edit the `config.json` file created
after the first install and rerun the installer (`sudo bash install.sh`).
