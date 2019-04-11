#!/bin/bash

CSV_VERSION="${1:-0.0.0}"

# TODO: tested with operator-sdk 0.7.0: should we require it?
which operator-sdk &> /dev/null || {
	echo "operator-sdk not found"
	exit 1
}

operator-sdk olm-catalog gen-csv --csv-version ${CSV_VERSION} && \
./build/update-olm.py deploy/olm-catalog/kubevirt-ssp-operator/${CSV_VERSION}/kubevirt-ssp-operator.v${CSV_VERSION}.clusterserviceversion.yaml
