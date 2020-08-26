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

echo $IMAGE_PATH

TAG="${IMAGE_PATH#*:}"

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
	sed "s|REPLACE_IMAGE|${IMAGE_PATH}|g ; s|REPLACE_VERSION|${TAG}|g" < ${MF}
done
) > _out/kubevirt-ssp-operator.yaml
