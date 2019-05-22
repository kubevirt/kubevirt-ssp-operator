#!/bin/bash

SCRIPTPATH=$( dirname $(readlink -f $0) )
source ${SCRIPTPATH}/testlib.sh

[ -z ${SSP_OP_POD_NAMESPACE} ] && exit 127
[ -z ${SSP_OP_POD_NAME} ] && exit 127

SSP_OP_POD_READY=$( oc get pod -o json -n ${SSP_OP_POD_NAMESPACE} ${SSP_OP_POD_NAME} | jq -r '.status.containerStatuses[0].ready' )
[ "${SSP_OP_POD_READY}" != "true" ] && exit 1
exit 0
