#!/bin/bash
set -e

SELF=$( realpath $0 )
BASEPATH=$( dirname $SELF )

NAMESPACE=${1:-kubevirt}

oc create -f ${BASEPATH}/../deploy/crds/kubevirt_v1_commontemplatesbundle_crd.yaml
oc create -f ${BASEPATH}/../deploy/crds/kubevirt_v1_nodelabellerbundle_crd.yaml
oc create -f ${BASEPATH}/../deploy/crds/kubevirt_v1_templatevalidator_crd.yaml

oc create -n ${NAMESPACE} -f ${BASEPATH}/../deploy/service_account.yaml
oc create -n ${NAMESPACE} -f ${BASEPATH}/../deploy/role.yaml

sed "s|namespace: kubevirt|namespace: ${NAMESPACE}|g" < ${BASEPATH}/../deploy/role_binding.yaml | \
	oc create -n ${NAMESPACE} -f -

REGISTRY=$(minishift openshift registry)
sed "s|REPLACE_IMAGE|${REGISTRY}/kubevirt/kubevirt-ssp-operator:devel|g" < ${BASEPATH}/../deploy/operator.yaml | \
	sed "s|imagePullPolicy: Always|imagePullPolicy: IfNotPresent|g" | \
	oc create -n ${NAMESPACE} -f -

sleep 5s

oc get pods -n ${NAMESPACE}
oc get pod -n ${NAMESPACE} -l "name=kubevirt-ssp-operator" -o yaml

sleep 5s
