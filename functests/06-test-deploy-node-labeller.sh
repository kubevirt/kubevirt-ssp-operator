#!/bin/bash

SCRIPTPATH=$( dirname $(readlink -f $0) )
source ${SCRIPTPATH}/testlib.sh

[ -z ${KV_NAMESPACE} ] && exit 127

RET=1
TEST_NS="${KV_NAMESPACE}"

oc apply -n ${TEST_NS} -f "${SCRIPTPATH}/node-labeller-unversioned-cr.yaml" || exit 2
# TODO: SSP-operator needs to improve its feedback mechanism
# fetching node-labeller images may take a while

wait_node_labeller_running ${TEST_NS} 5 60

for idx in $( seq 1 30); do
	echo "Waiting for node-labeller to label nodes"

	number_of_cpu=$( oc get nodes -o json | jq '.items[0].metadata.labels | keys | map(select(startswith("feature.node.kubernetes.io/cpu-model-"))) | length')
	number_of_cpu_features=$( oc get nodes -o json | jq '.items[0].metadata.labels | keys | map(select(startswith("feature.node.kubernetes.io/cpu-feature-"))) | length')

	echo "Number of CPU labels: $number_of_cpu"
	echo "Number of CPU features: $number_of_cpu_features"

	if [ $number_of_cpu -gt 0 ] && [ $number_of_cpu_features -gt 0 ]; then
		RET=0
		break
	fi
	sleep 2s
done

if [ $RET -eq 1 ] ; then
	exit 2
fi

#wait for ssp operator to set proper conditions
wait_for_condition ${TEST_NS} 5 40 "KubevirtNodeLabellerBundle" "Available" "True"
RET="$?"

oc delete -n ${TEST_NS} -f "${SCRIPTPATH}/node-labeller-unversioned-cr.yaml" || exit 2

exit $RET