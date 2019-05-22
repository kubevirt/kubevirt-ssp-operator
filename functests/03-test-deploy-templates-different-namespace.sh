#!/bin/bash

SCRIPTPATH=$( dirname $(readlink -f $0) )
source ${SCRIPTPATH}/testlib.sh

[ -z ${SSP_OP_POD_NAMESPACE} ] && exit 127
[ -z ${SSP_OP_POD_NAME} ] && exit 127

SSP_OP_POD_READY=$( oc get pod -o json -n ${SSP_OP_POD_NAMESPACE} ${SSP_OP_POD_NAME} | jq -r '.status.containerStatuses[0].ready' )
[ "${SSP_OP_POD_READY}" != "true" ] && exit 1

RET=1
TEST_NS=$(uuidgen)

oc create ns ${TEST_NS} || exit 2
oc create -n ${TEST_NS} -f "${SCRIPTPATH}/common-templates-versioned-cr.yaml" || exit 2
# TODO: SSP-operator needs to improve its feedback mechanism
sleep 10s
for idx in $( seq 1 30); do
	NUM=$(oc get templates -n ${TEST_NS} -l "template.kubevirt.io/type=base" -o json | jq ".items | length")
	if (( "${NUM}" > 0 )); then
		RET=0
		break
	fi
	sleep 2s
done
oc delete -n ${TEST_NS} -f "${SCRIPTPATH}/common-templates-versioned-cr.yaml" || exit 2
oc delete ns ${TEST_NS} || exit 2

exit $RET
