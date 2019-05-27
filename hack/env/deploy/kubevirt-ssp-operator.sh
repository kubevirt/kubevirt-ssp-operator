#!/bin/bash

set -e

if [ -z ${KUBEVIRT_SSP_OPERATOR_RELEASE} ]; then
	echo "missing RELEASE"
	exit 1
fi

oc create -f cluster/${KUBEVIRT_SSP_OPERATOR_RELEASE}/kubevirt-ssp-operator-crd.yaml 
oc create -n kubevirt -f deploy/service_account.yaml 
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:kubevirt:kubevirt-ssp-operator
oc create -n kubevirt -f deploy/role.yaml
oc create -n kubevirt -f deploy/role_binding.yaml
oc create -n kubevirt -f deploy/operator.yaml
