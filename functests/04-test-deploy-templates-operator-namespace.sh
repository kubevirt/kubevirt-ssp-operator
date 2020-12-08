#!/bin/bash

SCRIPTPATH=$( dirname $(readlink -f $0) )
source ${SCRIPTPATH}/testlib.sh

[ -z ${SSP_OP_POD_NAMESPACE} ] && exit 127

TEST_NS="${SSP_OP_POD_NAMESPACE}"

oc create -n ${TEST_NS} -f "${SCRIPTPATH}/common-templates-unversioned-cr.yaml" || exit 1

oc wait -f "${SCRIPTPATH}/common-templates-unversioned-cr.yaml" -n ${TEST_NS} --for=condition=Available --timeout=600s || exit 2

oc delete -n ${TEST_NS} -f "${SCRIPTPATH}/common-templates-unversioned-cr.yaml" || exit 3

exit 0
