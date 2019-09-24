#!/bin/bash

SCRIPTPATH=$( dirname $(readlink -f $0) )
source ${SCRIPTPATH}/testlib.sh

[ -z ${KV_NAMESPACE} ] && exit 127

RET=1
TEST_NS="${KV_NAMESPACE}"

oc create -n ${KV_NAMESPACE} -f "${SCRIPTPATH}/common-templates-versioned-cr.yaml" || exit 2

wait_for_deployment_ready ${TEST_NS} 5 50 "KubevirtCommonTemplatesBundle" "Running" "Successful"
RET="$?"
if [ $RET -eq 1 ]; then
    exit $RET
fi

for idx in $( seq 1 40); do
	NUM=$(oc get templates -n ${TEST_NS} -l "template.kubevirt.io/type=base" -o json | jq ".items | length")
	echo "templates found in ${TEST_NS}: ${NUM}"
	if [ "${NUM}" > 0 ]; then
		break
	fi
	sleep 3s
done

#wait for ssp operator to set proper conditions
wait_for_condition ${TEST_NS} 5 40 "KubevirtCommonTemplatesBundle" "Available" "True"
RET="$?"

oc delete -n ${TEST_NS} -f "${SCRIPTPATH}/common-templates-versioned-cr.yaml" || exit 2

exit $RET
