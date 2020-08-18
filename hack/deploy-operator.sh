#!/bin/bash
set -e

SELF=$( realpath $0 )
BASEPATH=$( dirname $SELF )

NAMESPACE=${1:-kubevirt}

oc create ns ${NAMESPACE}

oc apply -n ${NAMESPACE} -f ${BASEPATH}/../_out/kubevirt-ssp-operator-crd.yaml
oc apply -n ${NAMESPACE} -f ${BASEPATH}/../_out/kubevirt-ssp-operator-cr.yaml

sed "s|imagePullPolicy: Always|imagePullPolicy: IfNotPresent|g" < ${BASEPATH}/../_out/kubevirt-ssp-operator.yaml | \
    oc apply -n ${NAMESPACE} -f -

oc wait --for=condition=Available --timeout=600s -n $NAMESPACE deployment/kubevirt-ssp-operator

echo "Operator successfully deployed"

oc get pods -n $NAMESPACE