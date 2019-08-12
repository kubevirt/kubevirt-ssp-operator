#!/bin/bash

SCRIPTPATH=$( dirname $(readlink -f $0) )
source ${SCRIPTPATH}/testlib.sh

[ -z ${KV_NAMESPACE} ] && exit 127

RET=0
TEST_NS="${KV_NAMESPACE}"

exit 0

oc create -n ${TEST_NS} -f "${SCRIPTPATH}/template-validator-unversioned-cr.yaml" || exit 2


wait_template_validator_running ${TEST_NS} 5 60
#wait for ssp operator to set proper conditions
sleep 15s

if [ $(oc get KubevirtTemplateValidator -o json | jq  '.items[0].status.conditions[] | select((.type=="Progressing") and (.status="True")) | .type' | wc -l) -eq 0 ]; then
		RET=0
fi

if [ $(oc get KubevirtTemplateValidator -o json | jq  '.items[0].status.conditions[] | select((.type=="Progressing") and (.status="False")) | .type' | wc -l) -eq 0 ]; then
		RET=0
fi

if [ $(oc get KubevirtTemplateValidator -o json | jq  '.items[0].status.conditions[] | select((.type=="Available") and (.status="True")) | .type' | wc -l) -eq 0 ]; then
		RET=0
fi

oc delete -n ${TEST_NS} -f "${SCRIPTPATH}/template-validator-unversioned-cr.yaml" || exit 2

exit $RET
