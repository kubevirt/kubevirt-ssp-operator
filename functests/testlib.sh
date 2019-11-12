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

dump_template_validator_state() {
	NS="--all-namespaces"
	if [ -n "$1" ]; then
		NS="-n ${1}"
	fi
	oc get pods ${NS} -o yaml
	oc get pods --selector "kubevirt.io=virt-template-validator" ${NS} -o json
}

dunp_node_labeller_state() {
	NS="--all-namespaces"
	if [ -n "$1" ]; then
		NS="-n ${1}"
	fi
	oc get pods ${NS} -o yaml
	oc get pods --selector='app=kubevirt-node-labeller' ${NS} -o json
}

is_template_validator_running() {
	NS="--all-namespaces"
	if [ -n "$1" ]; then
		NS="-n ${1}"
	fi
	VERB="${V}"
	if [ -n "$2" ]; then
		VERB="${2}"
	fi
	local validator_pod=$( oc get pods --selector "kubevirt.io=virt-template-validator" ${NS} -o json )
	if [ -z "${validator_pod}" ]; then
		return 1
	fi
	local validator_status=$( echo ${validator_pod} | jq -r '.items[0].status' )
	local validator_phase=$( echo ${validator_pod} | jq -r '.items[0].status.phase' )
	(( ${VERB} >= 1 )) && echo "validator status: ${validator_status}"
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
	VERB="${V}"
	if [ -n "$2" ]; then
		VERB="${2}"
	fi
	local labeller_pod=$( oc get pods --selector='app=kubevirt-node-labeller' ${NS} -o json )
	local labeller_status=$( echo ${labeller_pod} | jq -r '.items[0].status' )
	local labeller_phase=$( echo ${labeller_pod} | jq -r '.items[0].status.phase' )
	(( ${VERB} >= 1 )) && echo "node-labeller status: ${labeller_status}"
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
		if is_template_validator_running $1 0; then
			return 0
		fi
	done
	dump_template_validator_state
	return 1
}

wait_node_labeller_running() {
	# $1 passthrough
	local wait_secs=${2:-2}
	local max_tries=${3:-15}
	for num in $( seq 1 ${max_tries} ); do
		(( ${V} >= 1 )) && echo "waiting for node-labeller availability: ${num}/${max_tries}"
		sleep ${wait_secs}s
		if is_node_labeller_running $1 0; then
			return 0
		fi
	done
	dump_node_labeller_state
	return 1
}

wait_node_labeller_deleted() {
	NS="--all-namespaces"
	if [ -n "$1" ]; then
		NS="-n ${1}"
	fi
	local wait_secs=${2:-2}
	local max_tries=${3:-15}
	for num in $( seq 1 ${max_tries} ); do
		if [ "$(oc get pods ${NS} | grep "kubevirt-node-labeller.*" | wc -l)" -eq 0 ]; then 
		  return 0
		fi
	done
}

wait_for_condition() {
	NS="--all-namespaces"
	if [ -n "$1" ]; then
		NS="-n ${1}"
	fi
	local wait_secs=${2:-2}
	local max_tries=${3:-15}
	local kind=$4
	local type=$5
	local status=$6
	for num in $( seq 1 ${max_tries} ); do
		(( ${V} >= 1 )) && echo "waiting for $type condition availability: ${num}/${max_tries}"
		if [ $(oc get ${kind} -o json ${NS} | jq '.items[0].status.conditions[] // [] | select((.type=="'${type}'") and (.status="'${status}'"))' | wc -l) -gt 0 ]; then
		  return 0
		fi
		sleep ${wait_secs}s
	done
	oc get ${kind} -o json ${NS}
	return 1
}

wait_for_deployment_ready() {
	NS="--all-namespaces"
	if [ -n "$1" ]; then
		NS="-n ${1}"
	fi
	local wait_secs=${2:-2}
	local max_tries=${3:-15}
	local kind=$4
	local type=$5
	local reason=$6
	for num in $( seq 1 ${max_tries} ); do
		(( ${V} >= 1 )) && echo "waiting for deployment to be ready: ${num}/${max_tries}"
		if [ $(oc get ${kind} -o json ${NS} | jq '.items[0].status.conditions[] // [] | select((.type=="'${type}'") and (.reason="'${reason}'"))' | wc -l) -gt 0 ]; then
		  return 0
		fi
		sleep ${wait_secs}s
	done
	return 1
}
