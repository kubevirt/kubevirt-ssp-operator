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

# Deploying kuebvirt
LATEST_KV=$(curl -L https://api.github.com/repos/kubevirt/kubevirt/releases | \
            jq '.[] | select(.prerelease==false) | .name' | sort -V | tail -n1 | tr -d '"')

oc apply -n $NAMESPACE -f https://github.com/kubevirt/kubevirt/releases/download/${LATEST_KV}/kubevirt-operator.yaml
oc apply -n $NAMESPACE -f https://github.com/kubevirt/kubevirt/releases/download/${LATEST_KV}/kubevirt-cr.yaml

oc apply -n $NAMESPACE -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    kubevirt.io: ""
  name: kubevirt-config
data:
  feature-gates: DataVolumes, CPUManager, LiveMigration #, ExperimentalIgnitionSupport, Sidecar, Snapshot
  selinuxLauncherType: virt_launcher.process
EOF

echo "Waiting for Kubevirt to be ready..."
oc wait --for=condition=Available --timeout=600s -n $NAMESPACE kv/kubevirt

# Deploying CDI
CDI_NAMESPACE=cdi
oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $CDI_NAMESPACE
EOF

LATEST_CDI=$(curl -L https://api.github.com/repos/kubevirt/containerized-data-importer/releases | \
             jq '.[] | select(.prerelease==false) | .tag_name' | sort -V | tail -n1 | tr -d '"')

oc apply -n $CDI_NAMESPACE -f https://github.com/kubevirt/containerized-data-importer/releases/download/${LATEST_CDI}/cdi-operator.yaml
oc apply -n $CDI_NAMESPACE -f https://github.com/kubevirt/containerized-data-importer/releases/download/${LATEST_CDI}/cdi-cr.yaml

echo "Waiting for CDI to be ready..."

oc wait --for=condition=Available --timeout=600s -n $CDI_NAMESPACE cdi/cdi

# Deploying the operator
oc apply -n ${NAMESPACE} -f ${BASEPATH}/../_out/kubevirt-ssp-operator-crd.yaml

oc apply -f ${BASEPATH}/../_out/kubevirt-ssp-operator.yaml

# Wait for the operator deployment to be ready
echo "Waiting for Kubevirt SSP Operator to be ready..."
oc wait --for=condition=Available --timeout=600s -n $NAMESPACE deployment/kubevirt-ssp-operator

# Wait for the operator operands to be ready
#oc wait --for=condition=Available --timeout=600s -n $NAMESPACE KubevirtCommonTemplatesBundle/kubevirt-common-template-bundle
#oc wait --for=condition=Available --timeout=600s -n $NAMESPACE KubevirtMetricsAggregation/kubevirt-metrics-aggregation
#oc wait --for=condition=Available --timeout=600s -n $NAMESPACE KubevirtNodeLabellerBundle/kubevirt-node-labeller-bundle
#oc wait --for=condition=Available --timeout=600s -n $NAMESPACE KubevirtTemplateValidator/kubevirt-template-validator

echo "##### Operator successfully deployed #####"

oc get pods -n $NAMESPACE
oc get pods -n $CDI_NAMESPACE
