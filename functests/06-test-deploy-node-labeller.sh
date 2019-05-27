#!/bin/bash

SCRIPTPATH=$( dirname $(readlink -f $0) )
source ${SCRIPTPATH}/testlib.sh

[ -z ${KV_NAMESPACE} ] && exit 127

RET=1
TEST_NS="${KV_NAMESPACE}"

oc create -n ${TEST_NS} -f "${SCRIPTPATH}/node-labeller-unversioned-cr.yaml" || exit 2
# TODO: SSP-operator needs to improve its feedback mechanism
# fetching node-labeller images may take a while

wait_node_labeller_running ${TEST_NS} 5 60

for idx in $( seq 1 30); do
	ANNOTATIONS=$( oc get nodes -o json | jq '.items[0].metadata.annotations | keys' )
	# any random CPU model annotation that *must* be present if everything's OK
	HAS_CPU=$( echo ${ANNOTATIONS} | jq 'map(endswith("cpu-model-kvm64")) | any' )
	# any random KVM info annotation that *must* be present if everything's OK
	HAS_KVM=$( echo ${ANNOTATIONS} | jq 'map(endswith("kvm-info-cap-hyperv-base")) | any' )
	if [ "${HAS_CPU}" == "true" ] && [ "${HAS_KVM}" == "true" ]; then
		RET=0
		break
	fi
	sleep 2s
done
oc delete -n ${TEST_NS} -f "${SCRIPTPATH}/node-labeller-unversioned-cr.yaml" || exit 2

exit $RET
