#!/bin/bash

SCRIPTPATH=$( dirname $(readlink -f $0) )
source ${SCRIPTPATH}/testlib.sh

RET=1
TEST_NS="openshift"  # TODO: check this exists?

{ oc get crds | grep -q prometheusrule; } || exit 99

oc create -n ${TEST_NS} -f "${SCRIPTPATH}/aggregation-rules-unversioned-cr.yaml" || exit 2
# TODO: SSP-operator needs to improve its feedback mechanism
sleep 21s
for idx in $( seq 1 30); do
	NUM=$(oc get prometheusrules -n ${TEST_NS} -l "kubevirt.io=" -o json | jq ".items | length")
	(( ${V} >= 1 )) && echo "prometheus rules found in ${TEST_NS}: ${NUM}"
	if (( "${NUM}" > 0 )); then
		(( ${V} >= 1 )) && echo "enough prometheus rules found in ${TEST_NS}"
		RET=0
		break
	fi
	sleep 3s
done
oc delete -n ${TEST_NS} -f "${SCRIPTPATH}/aggregation-rules-unversioned-cr.yaml" || exit 2

exit $RET
