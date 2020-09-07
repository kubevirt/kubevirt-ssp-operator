#!/bin/bash

set -ex

SELF=$( realpath $0 )
BASEPATH=$( dirname $SELF )

PLACEHOLDER_CSV_VERSION="9999.9999.9999"

# Create CSV with placeholder version. The version
# has to be semver compatible in order for the 
# operator sdk to create it for us. That's why we
# are using the absurd 9999.9999.9999 version here. 
#sed -i "s/PLACEHOLDER_CSV_VERSION/${PLACEHOLDER_CSV_VERSION}/g" deploy/olm-catalog/manifests/kubevirt-ssp-operator.clusterserviceversion.yaml

# Generate CSV
./operator-sdk-csv olm-catalog gen-csv --csv-version ${PLACEHOLDER_CSV_VERSION}

 # Add CSV descriptions
./build/update-csv.py deploy/olm-catalog/kubevirt-ssp-operator/${PLACEHOLDER_CSV_VERSION}/kubevirt-ssp-operator.v${PLACEHOLDER_CSV_VERSION}.clusterserviceversion.yaml > deploy/olm-catalog/kubevirt-ssp-operator.clusterserviceversion.yaml

# Remove generated tmp dir
rm -rf deploy/olm-catalog/kubevirt-ssp-operator
sed -i "s/${PLACEHOLDER_CSV_VERSION}/PLACEHOLDER_CSV_VERSION/g" deploy/olm-catalog/kubevirt-ssp-operator.clusterserviceversion.yaml
