#!/bin/bash

set -e

export SCRIPTPATH=$( dirname $(readlink -f $0) )
export KUBEVIRT_RELEASE=${1:-v0.17.0} # note the leading "v"
export KUBEVIRT_SSP_OPERATOR_RELEASE=${2:-1.0.1}  # note WITHOUT leading "v"

${SCRIPTPATH}/oc-cluster/down.sh
