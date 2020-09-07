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

# Use image digest instead of tag
# Pull the remote image to get the digest
docker pull $IMAGE_PATH

IMAGE_PATH_NO_TAG=$(echo $IMAGE_PATH | cut -d':' -f 1)
IMAGE_DIGEST=$(docker images --digests | grep $IMAGE_PATH_NO_TAG | grep $TAG | tr -s ' ' | cut -d' ' -f 3)
IMAGE_PATH_WITH_DIGEST=${IMAGE_PATH_NO_TAG}@${IMAGE_DIGEST}

(
for CRD in $( ls deploy/crds/*crd.yaml ); do
	echo "---"
	cat ${CRD}
done
) > _out/kubevirt-ssp-operator-crd.yaml

(
for CR in $( ls deploy/crds/*cr.yaml ); do
	echo "---"
	cat ${CR}
done
) > _out/kubevirt-ssp-operator-cr.yaml

(
for MF in deploy/service_account.yaml deploy/role.yaml deploy/role_binding.yaml deploy/operator.yaml; do
	echo "---"
	sed "s|REPLACE_IMAGE|${IMAGE_PATH_WITH_DIGEST}|g ; s|REPLACE_VERSION|${TAG}|g" < ${MF}
done
) > _out/kubevirt-ssp-operator.yaml

${BASEPATH}/../build/csv-generator.sh --csv-version=${VERSION} \
										--namespace=kubevirt \
										--operator-image=${IMAGE_PATH_WITH_DIGEST} \
										--operator-version=${TAG} \
										> _out/olm-catalog/kubevirt-ssp-operator.clusterserviceversion.yaml

cp deploy/crds/*crd.yaml _out/olm-catalog

cat << EOF > _out/olm-catalog/kubevirt-ssp-operator.package.yaml
packageName: kubevirt-ssp-operator
channels:
- name: ${CHANNEL}
  currentCSV: kubevirt-ssp-operator.${TAG}
EOF
