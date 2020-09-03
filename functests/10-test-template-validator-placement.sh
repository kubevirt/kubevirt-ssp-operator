#!/bin/bash

SCRIPTPATH=$( dirname $(readlink -f $0) )
source ${SCRIPTPATH}/testlib.sh

RET=0
TEST_NS="${KV_NAMESPACE}"

oc create -n ${TEST_NS} -f "${SCRIPTPATH}/10-template-validator-unversioned-cr.yaml" || exit 2

# Wait for the operator to create the deployment, we don't care if pods are actually ready, as
# we only check for the pod scheduling fields
DEPLOYMENT_FOUND=false
for i in {1..20}; do
  oc get -n ${TEST_NS} deploy virt-template-validator
  EXIT_CODE=$?
  if (( $EXIT_CODE == 0 )); then
    DEPLOYMENT_FOUND=true
    break
  else
    sleep 10
  fi
done

if [ "$DEPLOYMENT_FOUND" == "false" ]; then
  echo "virt-template-validator deployment was not found"
  exit 1
fi

NODE_SELECTOR=$(oc get -n ${TEST_NS} deploy virt-template-validator -ojson | jq '.spec.template.spec.nodeSelector.testKey' | tr -d '"')
if [ "$NODE_SELECTOR" != "testValue" ]; then
  echo $NODE_SELECTOR
  echo "template validator deployment is missing proper nodeSelector"
  RET=1
fi

TOLERATION=$(oc get -n ${TEST_NS} deploy virt-template-validator -ojson | jq '.spec.template.spec.tolerations[0].key' | tr -d '"')
if [ "$TOLERATION" != "testKey" ]; then
  echo $TOLERATION
  echo "template validator deployment is missing proper tolerations"
  RET=1
fi

AFFINITY=$(oc get -n ${TEST_NS} deploy virt-template-validator -ojson | jq '.spec.template.spec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].key' | tr -d '"')
if [ "$AFFINITY" != "testKey" ]; then
  echo $AFFINITY
  echo "template validator deployment is missing proper affinity"
  RET=1
fi

oc delete -n ${TEST_NS} -f "${SCRIPTPATH}/10-template-validator-unversioned-cr.yaml" || exit 2

exit $RET
