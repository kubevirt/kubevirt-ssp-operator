#!/bin/bash

SCRIPTPATH=$( dirname $(readlink -f $0) )
source ${SCRIPTPATH}/testlib.sh

# If the CRD OpenAPI schema is not complete (ALL fields have descriptions) the CRD is not explainable
# and an 'empty description' would appear and this test would fail
RET=0

oc explain kubevirtcommontemplatesbundles | grep "<empty>" >> /dev/null && RET=1
oc explain kubevirtmetricsaggregations | grep "<empty>" >> /dev/null && RET=1
oc explain kubevirtnodelabellerbundles | grep "<empty>" >> /dev/null && RET=1
oc explain kubevirttemplatevalidators | grep "<empty>" >> /dev/null && RET=1

exit $RET
