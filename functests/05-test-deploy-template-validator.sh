#!/bin/bash

# This script needs openshift 4.*

SCRIPTPATH=$( dirname $(readlink -f $0) )
source ${SCRIPTPATH}/testlib.sh

RET=1
TEST_NS="${KV_NAMESPACE}"

oc create -n ${TEST_NS} -f "${SCRIPTPATH}/template-validator-unversioned-cr.yaml" || exit 2
# TODO: SSP-operator needs to improve its feedback mechanism
wait_template_validator_running ${TEST_NS} 5 600

if is_template_validator_running ${TEST_NS}; then
	RET=0
else
	exit 2
fi

#wait for ssp operator to set proper conditions
wait_for_condition ${TEST_NS} 5 40 "KubevirtTemplateValidator" "Available" "True"
RET="$?"

oc delete -n ${TEST_NS} -f "${SCRIPTPATH}/template-validator-unversioned-cr.yaml" || exit 2

exit $RET
