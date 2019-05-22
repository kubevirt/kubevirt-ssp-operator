#!/bin/bash

SCRIPTPATH=$( dirname $(readlink -f $0) )
source ${SCRIPTPATH}/testlib.sh

[ -z ${SSP_OP_POD_NAMESPACE} ] && exit 127
[ -z ${SSP_OP_POD_NAME} ] && exit 127

RET=1
TEST_NS="kubevirt"

oc create -n ${TEST_NS} -f "${SCRIPTPATH}/template-validator-unversioned-cr.yaml" || exit 2
# TODO: SSP-operator needs to improve its feedback mechanism
sleep 10s
for idx in $( seq 1 30); do
	VALIDATOR_JSON=$( oc get pods -n ${TEST_NS} -l "kubevirt.io=virt-template-validator" -o json )
	NUM=$( echo ${VALIDATOR_JSON} | jq '.items | length' )
	if [ "${NUM}" == "1" ]; then
		VALIDATOR_POD_JSON="$( echo ${VALIDATOR_JSON} | jq '.items[0]' )"
		VALIDATOR_READY=$( echo ${VALIDATOR_POD_JSON} | jq .status.containerStatuses[0].ready )
		if [ "${VALIDATOR_READY}" == "true" ]; then
			RET=0
			break
		fi
	fi
	sleep 2s
done
oc delete -n ${TEST_NS} -f "${SCRIPTPATH}/template-validator-unversioned-cr.yaml" || exit 2

exit $RET
