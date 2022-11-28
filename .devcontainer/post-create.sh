#!/bin/bash
set -e

## Install the Statis Web Apps CLI
npm install -g @azure/static-web-apps-cli

## Install the Azure Functions Core Tools
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg

sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/debian/$(lsb_release -rs | cut -d'.' -f 1)/prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'

sudo apt-get update
sudo apt-get install azure-functions-core-tools-4

sudo apt-get install -y python3-venv


az bicep Install
