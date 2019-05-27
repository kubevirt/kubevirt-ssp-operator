#!/bin/bash

set -e

oc cluster up
sleep 20s # FIXME

oc login -u system:admin
