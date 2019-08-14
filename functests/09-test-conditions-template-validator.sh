#!/bin/bash

SCRIPTPATH=$( dirname $(readlink -f $0) )
source ${SCRIPTPATH}/testlib.sh

[ -z ${KV_NAMESPACE} ] && exit 127

RET=1
TEST_NS="${KV_NAMESPACE}"

oc create -n ${TEST_NS} -f "${SCRIPTPATH}/template-validator-unversioned-cr.yaml" || exit 2


wait_template_validator_running ${TEST_NS} 5 60

#wait for ssp operator to set proper conditions
wait_for_condition ${TEST_NS} 5 20 "KubevirtTemplateValidator" "Available" "True"
RET="$?"

oc delete -n ${TEST_NS} -f "${SCRIPTPATH}/template-validator-unversioned-cr.yaml" || exit 2

exit $RET
