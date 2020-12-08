#!/bin/bash

SCRIPTPATH=$( dirname $(readlink -f $0) )
source ${SCRIPTPATH}/testlib.sh

TEST_NS=$(uuidgen)

oc create ns ${TEST_NS} || exit 1
oc create -n ${TEST_NS} -f "${SCRIPTPATH}/common-templates-unversioned-cr.yaml" || exit 2

oc wait -f "${SCRIPTPATH}/common-templates-unversioned-cr.yaml" -n ${TEST_NS} --for=condition=Available --timeout=600s || exit 3

oc delete -n ${TEST_NS} -f "${SCRIPTPATH}/common-templates-unversioned-cr.yaml" || exit 4
oc delete ns ${TEST_NS} || exit 5

exit 0
