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

#wait for ssp operator to set proper conditions
wait_for_condition ${TEST_NS} 5 40 "KubevirtNodeLabellerBundle" "Available" "True"
RET="$?"

oc delete -n ${TEST_NS} -f "${SCRIPTPATH}/node-labeller-unversioned-cr.yaml" || exit 2

exit $RET