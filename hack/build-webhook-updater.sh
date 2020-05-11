#!/bin/bash

set -ex

export GOPROXY=off
export GOFLAGS=-mod=vendor
cd cmd/webhook-updater && go build -v .
