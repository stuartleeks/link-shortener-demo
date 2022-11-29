#!/bin/bash
set -e

## Install the Statis Web Apps CLI
# npm install -g @azure/static-web-apps-cli
# Due to an issue with deployment in 1.0.3, we install from source (until 1.0.4 is released)
git clone https://github.com/azure/static-web-apps-cli /tmp/swa
(cd /tmp/swa && git checkout 2cd0e980ea4bf604df10fd5d63149b20b292e916 && npm install && npm link)
echo "alias swa=$(which swa)" >> ~/.bashrc

## Install the Azure Functions Core Tools
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg

sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/debian/$(lsb_release -rs | cut -d'.' -f 1)/prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'

sudo apt-get update
sudo apt-get install azure-functions-core-tools-4

sudo apt-get install -y python3-venv


az bicep Install
