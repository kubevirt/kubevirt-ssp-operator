#!/bin/bash

set -e

if [ -z ${KUBEVIRT_RELEASE} ]; then
	echo "missing RELEASE"
	exit 1
fi

oc apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml
oc apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml
oc wait -n kubevirt kubevirt.kubevirt.io/kubevirt --for condition=Ready
