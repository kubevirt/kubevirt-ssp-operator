#!/bin/bash
set -e

SELF=$( realpath $0 )
BASEPATH=$( dirname $SELF )

NAMESPACE=${1:-kubevirt}

oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPACE}
EOF

oc apply -n ${NAMESPACE} -f ${BASEPATH}/../_out/kubevirt-ssp-operator-crd.yaml
#oc apply -n ${NAMESPACE} -f ${BASEPATH}/../_out/kubevirt-ssp-operator-cr.yaml

sed "s|imagePullPolicy: Always|imagePullPolicy: IfNotPresent|g" < ${BASEPATH}/../_out/kubevirt-ssp-operator.yaml | \
    oc apply -n ${NAMESPACE} -f -

# Wait for the operator deployment to be ready
oc wait --for=condition=Available --timeout=600s -n $NAMESPACE deployment/kubevirt-ssp-operator

# Wait for the operator operands to be ready
#oc wait --for=condition=Available --timeout=600s -n $NAMESPACE KubevirtCommonTemplatesBundle/kubevirt-common-template-bundle
#oc wait --for=condition=Available --timeout=600s -n $NAMESPACE KubevirtMetricsAggregation/kubevirt-metrics-aggregation
#oc wait --for=condition=Available --timeout=600s -n $NAMESPACE KubevirtNodeLabellerBundle/kubevirt-node-labeller-bundle
#oc wait --for=condition=Available --timeout=600s -n $NAMESPACE KubevirtTemplateValidator/kubevirt-template-validator

echo "Operator successfully deployed"

oc get pods -n $NAMESPACE