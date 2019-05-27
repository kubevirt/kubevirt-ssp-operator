#!/bin/bash

export SSP_OP_POD_NAME=""
export SSP_OP_POD_NAMESPACE=""
export SSP_OP_MANIFEST_JSON=$( oc get pods --all-namespaces -l name=kubevirt-ssp-operator -o json | jq .items[0] )

if [ -z "${SSP_OP_MANIFEST_JSON}" ] || [ "${SSP_OP_MANIFEST_JSON}" == "null" ]; then
	export SSP_OP_MANIFEST_JSON=""
else
	export SSP_OP_POD_NAME=$( echo "${SSP_OP_MANIFEST_JSON}" | jq -r .metadata.name )
	export SSP_OP_POD_NAMESPACE=$( echo "${SSP_OP_MANIFEST_JSON}" | jq -r .metadata.namespace )
fi

export KV_NAMESPACE=""
export KV_OP_POD_NAMESPACE=""
export KV_OP_MANIFEST_JSON=$( oc get pods --all-namespaces -l 'kubevirt.io=virt-operator' -o json | jq -r '.items[0]' )
if [ -z "${KV_OP_MANIFEST_JSON}" ] || [ "${KV_OP_MANIFEST_JSON}" == "null" ]; then
	export KV_OP_MANIFEST_JSON=""
else
	export KV_OP_POD_NAMESPACE=$( echo "${KV_OP_MANIFEST_JSON}" | jq -r .metadata.namespace )
	export KV_NAMESPACE="${KV_OP_POD_NAMESPACE}"
fi

is_template_validator_running() {
	NS="--all-namespaces"
	if [ -n "$1" ]; then
		NS="-n ${1}"
	fi
	local validator_phase=$( oc get pods --selector "kubevirt.io=virt-template-validator" ${NS} -o json | jq -r '.items[0].status.phase' )
	(( ${V} >= 1 )) && echo "validator phase : ${validator_phase}"
	if [ "${validator_phase}" == "Running" ]; then
		return 0
	fi
	return 1
}

is_node_labeller_running() {
	NS="--all-namespaces"
	if [ -n "$1" ]; then
		NS="-n ${1}"
	fi
	local labeller_phase=$( oc get pods --selector='app=kubevirt-node-labeller' ${NS} -o json | jq -r '.items[0].status.phase' )
	(( ${V} >= 1 )) && echo "node-labeller phase: ${labeller_phase}"
	if [ "${labeller_phase}" == "Running" ]; then
		return 0
	fi
	return 1
}

wait_template_validator_running() {
	# $1 passthrough
	local wait_secs=${2:-2}
	local max_tries=${3:-15}
	for num in $( seq 1 ${max_tries} ); do
		(( ${V} >= 1 )) && echo "waiting for template-validator availability: ${num}/${max_tries}"
		sleep ${wait_secs}s
		is_template_validator_running $1 && break
	done
}

wait_node_labeller_running() {
	# $1 passthrough
	local wait_secs=${2:-2}
	local max_tries=${3:-15}
	for num in $( seq 1 ${max_tries} ); do
		(( ${V} >= 1 )) && echo "waiting for node-labeller availability: ${num}/${max_tries}"
		sleep ${wait_secs}s
		is_node_labeller_running $1 && break
	done
}
