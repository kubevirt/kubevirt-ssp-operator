#!/bin/bash

SCRIPTPATH=$( dirname $(readlink -f $0) )
source ${SCRIPTPATH}/testlib.sh

[ -z ${SSP_OP_POD_NAMESPACE} ] && exit 127

RET=1
TEST_NS="${SSP_OP_POD_NAMESPACE}"

oc create -n ${TEST_NS} -f "${SCRIPTPATH}/common-templates-versioned-cr.yaml" || exit 2
# TODO: SSP-operator needs to improve its feedback mechanism
sleep 21s
for idx in $( seq 1 40); do
	NUM=$(oc get templates -n ${TEST_NS} -l "template.kubevirt.io/type=base" -o json | jq ".items | length")
	(( ${V} >= 1 )) && echo "templates found in ${TEST_NS}: ${NUM}"
	if (( "${NUM}" > 0 )); then
		(( ${V} >= 1 )) && echo "enough templates found in ${TEST_NS}"
		RET=0
		break
	fi
	sleep 3s
done
oc delete -n ${TEST_NS} -f "${SCRIPTPATH}/common-templates-versioned-cr.yaml" || exit 2

exit $RET
