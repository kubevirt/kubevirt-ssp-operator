#!/bin/bash
set -e

SELF=$( realpath $0 )
BASEPATH=$( dirname $SELF )

NAMESPACE=${1:-kubevirt}

source ${BASEPATH}/_common.sh

oc create -f ${BASEPATH}/../deploy/crds/kubevirt_v1_commontemplatesbundle_crd.yaml
oc create -f ${BASEPATH}/../deploy/crds/kubevirt_v1_nodelabellerbundle_crd.yaml
oc create -f ${BASEPATH}/../deploy/crds/kubevirt_v1_templatevalidator_crd.yaml
oc create -f ${BASEPATH}/../deploy/crds/kubevirt_v1_metricsaggregation_crd.yaml

# we need to do this before to deploy any manifest, so if this fails we bail out as soon as possible.
LAST_TAG=""
if [ "${CI}" != "true" ] || [ "${TRAVIS}" != "true" ]; then
	# TODO: consume releases, not tags
	# TODO: check if the github APIs guarantee the ordering
	LAST_TAG=$( _curl -s https://api.github.com/repos/MarSik/kubevirt-ssp-operator/tags | jq -r '.[].name' | sort -r | head -1 )
fi

oc create -n ${NAMESPACE} -f ${BASEPATH}/../deploy/service_account.yaml
oc create -n ${NAMESPACE} -f ${BASEPATH}/../deploy/role.yaml

sed "s|namespace: kubevirt|namespace: ${NAMESPACE}|g" < ${BASEPATH}/../deploy/role_binding.yaml | \
	oc create -n ${NAMESPACE} -f -

if [ "${CI}" == "true" ] && [ "${TRAVIS}" == "true" ]; then
	REGISTRY=$(minishift openshift registry)
	sed "s|REPLACE_IMAGE|${REGISTRY}/kubevirt/kubevirt-ssp-operator:devel|g" < ${BASEPATH}/../deploy/operator.yaml | \
		sed "s|imagePullPolicy: Always|imagePullPolicy: IfNotPresent|g" | \
		oc create -n ${NAMESPACE} -f -

	sleep 5s

	oc get pods -n ${NAMESPACE}
	oc get pod -n ${NAMESPACE} -l "name=kubevirt-ssp-operator" -o yaml

	sleep 5s
else
	sed "s|REPLACE_IMAGE|quay.io/fromani/kubevirt-ssp-operator-container:${LAST_TAG}|g" < ${BASEPATH}/../deploy/operator.yaml | \
		grep -v FIXME | \
		oc create -n ${NAMESPACE} -f -
fi
