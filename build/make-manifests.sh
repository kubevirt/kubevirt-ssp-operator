#!/bin/bash

VERSION="${1:-0.0.0}"
CLUSTER_VERSIONED_DIR="cluster/${VERSION}"
MANIFESTS_DIR="manifests/kubevirt-ssp-operator"
MANIFESTS_VERSIONED_DIR="${MANIFESTS_DIR}/v${VERSION}"
IMAGE_PATH="quay.io/fromani/kubevirt-ssp-operator-container:latest"

# TODO: tested with operator-sdk 0.7.0: should we require it?
which operator-sdk &> /dev/null || {
	echo "operator-sdk not found (see https://github.com/operator-framework/operator-sdk)"
	exit 1
}

which operator-courier &> /dev/null || {
	echo "operator-courier not found (see https://github.com/operator-framework/operator-courier)"
	exit 2
}


mkdir -p ${CLUSTER_VERSIONED_DIR}
mkdir -p ${MANIFESTS_VERSIONED_DIR}

(
for CRD in $( ls deploy/crds/kubevirt_*crd.yaml ); do
	echo "---"
	cat ${CRD}
done
) > ${CLUSTER_VERSIONED_DIR}/kubevirt-ssp-operator-crd.yaml

(
for CR in $( ls deploy/crds/kubevirt_*cr.yaml ); do
	echo "---"
	cat ${CR}
done
) > ${CLUSTER_VERSIONED_DIR}/kubevirt-ssp-operator-cr.yaml

(
for MF in deploy/service_account.yaml deploy/role.yaml deploy/role_binding.yaml deploy/operator.yaml; do
	echo "---"
	sed "s|REPLACE_IMAGE|${IMAGE_PATH}|" < ${MF}
done
) > ${CLUSTER_VERSIONED_DIR}/kubevirt-ssp-operator.yaml

operator-sdk olm-catalog gen-csv --csv-version ${VERSION}

./build/update-olm.py \
	deploy/olm-catalog/kubevirt-ssp-operator/${VERSION}/kubevirt-ssp-operator.v${VERSION}.clusterserviceversion.yaml > \
	${MANIFESTS_VERSIONED_DIR}/kubevirt-ssp-operator.v${VERSION}.clusterserviceversion.yaml

# caution: operator-courier (as in 5a4852c) whants *one* entity per yaml file (e.g. it does NOT use safe_load_all)
for CRD in $( ls deploy/crds/kubevirt_*crd.yaml ); do
	cp ${CRD} ${MANIFESTS_VERSIONED_DIR}
done

cat << EOF > ${MANIFESTS_VERSIONED_DIR}/kubevirt-ssp-operator.package.yaml
packageName: kubevirt-ssp-operator
channels:
- name: beta
  currentCSV: kubevirt-ssp-operator.v${VERSION}
EOF

## needed to build the registry
cp ${MANIFESTS_VERSIONED_DIR}/kubevirt-ssp-operator.package.yaml ${MANIFESTS_DIR}

operator-courier verify ${MANIFESTS_VERSIONED_DIR} && echo "OLM verify passed" || echo "OLM verify failed"

rm ${MANIFESTS_VERSIONED_DIR}/kubevirt-ssp-operator.package.yaml
