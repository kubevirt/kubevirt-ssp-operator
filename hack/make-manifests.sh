#!/bin/bash

set -ex

SELF=$( realpath $0 )
BASEPATH=$( dirname $SELF )

# intentionally "impossible"/obviously wrong version
IMAGE_PATH=$1

if [ -z "$IMAGE_PATH" ]; then
  echo "Expecting image path as \$1"
  exit 1
fi

TAG="${IMAGE_PATH#*:}"
VERSION=${TAG#v}  # prune initial 'v', which should be present
CHANNEL="beta"
CLUSTER_VERSIONED_DIR="cluster/${VERSION}"
MANIFESTS_DIR="manifests/kubevirt-ssp-operator"
MANIFESTS_VERSIONED_DIR="${MANIFESTS_DIR}/${TAG}"

HAVE_COURIER=0
if which operator-courier &> /dev/null; then
	HAVE_COURIER=1
fi

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
	sed "s|REPLACE_IMAGE|${IMAGE_PATH}|g ; s|REPLACE_VERSION|${TAG}|g" < ${MF}
done
) > ${CLUSTER_VERSIONED_DIR}/kubevirt-ssp-operator.yaml

${BASEPATH}/../build/csv-generator.sh --csv-version=${VERSION} --namespace=placeholder --operator-image=REPLACE_IMAGE --operator-version=REPLACE_VERSION > ${MANIFESTS_VERSIONED_DIR}/kubevirt-ssp-operator.${TAG}.clusterserviceversion.yaml

# caution: operator-courier (as in 5a4852c) wants *one* entity per yaml file (e.g. it does NOT use safe_load_all)
for CRD in $( ls deploy/crds/kubevirt_*crd.yaml ); do
	cp ${CRD} ${MANIFESTS_VERSIONED_DIR}
done

cat << EOF > ${MANIFESTS_VERSIONED_DIR}/kubevirt-ssp-operator.package.yaml
packageName: kubevirt-ssp-operator
channels:
- name: ${CHANNEL}
  currentCSV: kubevirt-ssp-operator.${TAG}
EOF

# needed to make operator-courier happy
cp ${MANIFESTS_VERSIONED_DIR}/kubevirt-ssp-operator.package.yaml ${MANIFESTS_DIR}

if [ "${HAVE_COURIER}" == "1" ]; then
	operator-courier verify ${MANIFESTS_VERSIONED_DIR} && echo "OLM verify passed" || echo "OLM verify failed"
fi

## otherwise the image registry won't build
# TODO: who's at fault here? the registry build procedure? the courier? something else?
rm ${MANIFESTS_VERSIONED_DIR}/kubevirt-ssp-operator.package.yaml
