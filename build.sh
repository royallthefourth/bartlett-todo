#!/usr/bin/env bash

set -e
go build .

unset NPM_CONFIG_PREFIX
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | dash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm current
nvm install 10.15

npm install
npm run build
gzip -kf static/*
