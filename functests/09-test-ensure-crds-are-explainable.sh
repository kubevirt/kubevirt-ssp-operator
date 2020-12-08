#!/bin/bash

SCRIPTPATH=$( dirname $(readlink -f $0) )
RES_DIR=${SCRIPTPATH}/$(basename -s .sh $0)
source ${SCRIPTPATH}/testlib.sh

echo "[test_id:4864]: SSP CRs should be explainable"
# If the CRD OpenAPI schema is not complete (ALL fields have descriptions) the CRD is not explainable
# and an 'empty description' would appear and this test would fail
RET=0

oc explain kubevirtcommontemplatesbundles | grep "<empty>" >> /dev/null && RET=1
oc explain kubevirtmetricsaggregations | grep "<empty>" >> /dev/null && RET=1
oc explain kubevirtnodelabellerbundles | grep "<empty>" >> /dev/null && RET=1
oc explain kubevirttemplatevalidators | grep "<empty>" >> /dev/null && RET=1

# Also check the if the CRDs are upgradeable
oc delete crd kubevirtcommontemplatesbundles.ssp.kubevirt.io
oc delete crd kubevirtmetricsaggregations.ssp.kubevirt.io
oc delete crd kubevirtnodelabellerbundles.ssp.kubevirt.io
oc delete crd kubevirttemplatevalidators.ssp.kubevirt.io

oc apply -f ${RES_DIR}/old-crds.yaml

oc apply -f ${SCRIPTPATH}/../deploy/crds/ssp.kubevirt.io_kubevirtcommontemplatesbundles_crd.yaml
oc apply -f ${SCRIPTPATH}/../deploy/crds/ssp.kubevirt.io_kubevirtmetricsaggregations_crd.yaml
oc apply -f ${SCRIPTPATH}/../deploy/crds/ssp.kubevirt.io_kubevirtnodelabellerbundles_crd.yaml
oc apply -f ${SCRIPTPATH}/../deploy/crds/ssp.kubevirt.io_kubevirttemplatevalidators_crd.yaml

# I couldn't figure out what caused the CRD to become unavailable to 'oc explain', and it seems that 
# just waiting for a few seconds resolves the issue
sleep 30

oc explain kubevirtcommontemplatesbundles
oc explain kubevirtmetricsaggregations
oc explain kubevirtnodelabellerbundles
oc explain kubevirttemplatevalidators

# oc explain kubevirtcommontemplatesbundles | grep "<empty>" >> /dev/null && RET=1
# oc explain kubevirtmetricsaggregations | grep "<empty>" >> /dev/null && RET=1
# oc explain kubevirtnodelabellerbundles | grep "<empty>" >> /dev/null && RET=1
# oc explain kubevirttemplatevalidators | grep "<empty>" >> /dev/null && RET=1

exit $RET
