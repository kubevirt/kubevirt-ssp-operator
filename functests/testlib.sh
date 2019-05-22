#!/bin/bash

export SSP_OP_POD_NAME=""
export SSP_OP_POD_NAMESPACE=""
export SSP_OP_MANIFEST_JSON=$(oc get pods --all-namespaces -l name=kubevirt-ssp-operator -o json | jq .items[0] )

if [ -z "${SSP_OP_MANIFEST_JSON}" ] || [ "${SSP_OP_MANIFEST_JSON}" == "null" ]; then
	export SSP_OP_MANIFEST_JSON=""
else
	export SSP_OP_POD_NAME=$( echo "${SSP_OP_MANIFEST_JSON}" | jq -r .metadata.name )
	export SSP_OP_POD_NAMESPACE=$( echo "${SSP_OP_MANIFEST_JSON}" | jq -r .metadata.namespace )
fi
