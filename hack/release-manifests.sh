#!/bin/bash
set -ex

SELF=$( realpath $0 )
BASEPATH=$( dirname $SELF )

TAG="${1:-v0.0.0}"
VERSION=${TAG#v}  # prune initial 'v', which should be present

cp manifests/kubevirt-ssp-operator/kubevirt-ssp-operator.package.yaml _out
cp manifests/kubevirt-ssp-operator/${TAG}/kubevirt-ssp-operator.${TAG}.clusterserviceversion.yaml _out
cp cluster/${VERSION}/kubevirt-ssp-operator-crd.yaml _out
cp cluster/${VERSION}/kubevirt-ssp-operator-cr.yaml _out
cp cluster/${VERSION}/kubevirt-ssp-operator.yaml _out
