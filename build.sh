#!/usr/bin/env bash

set -e
go build .
npm run build
gzip -kf static/*
