#!/bin/bash

# generate all-in-one manifests, easier to consume, e.g. for HCO integration
# the master source the content of deploy/

VERSION="${1:-0.0.0}"
MANIFESTS_DIR="manifests/v${VERSION}"
IMAGE_PATH="quay.io/fromani/kubevirt-ssp-operator-container:latest"

mkdir -p ${MANIFESTS_DIR}

(
for CRD in $( ls deploy/crds/kubevirt_*crd.yaml ); do
	echo "---"
	cat ${CRD}
done
) > ${MANIFESTS_DIR}/kubevirt-ssp-operator-v${VERSION}.crds.yaml

(
for CR in $( ls deploy/crds/kubevirt_*cr.yaml ); do
	echo "---"
	cat ${CR}
done
) > ${MANIFESTS_DIR}/kubevirt-ssp-operator-v${VERSION}.crs.yaml

(
for MF in deploy/service_account.yaml deploy/role.yaml deploy/role_binding.yaml deploy/operator.yaml; do
	echo "---"
	sed "s|REPLACE_IMAGE|${IMAGE_PATH}|" < ${MF}
done
) > ${MANIFESTS_DIR}/kubevirt-ssp-operator-v${VERSION}.yaml

echo "built these manifests:"
ls ${MANIFESTS_DIR}/*.yaml
