#!/bin/bash
set -e

SELF=$( realpath $0 )
BASEPATH=$( dirname $SELF )

source ${BASEPATH}/_common.sh

if [ -n "${TRAVIS_TAG}" ]; then
	# travis build, generating a new tag
	echo "${TRAVIS_TAG}"
else
	# refreshing manifests, getting the last stable tag
	_curl -s 'https://api.github.com/repos/MarSik/kubevirt-ssp-operator/tags' | jq -r '.[].name' | sort -r | head -1
fi
