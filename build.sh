#!/usr/bin/env bash

set -e
go build .
npm install
npm run build
gzip -kf static/*
