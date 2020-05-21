#!/bin/bash

set -e

MANIFESTS_GENERATED_DIR="manifests/generated"
CRDS_DIR="deploy/crds"
if ! [ -d $MANIFESTS_GENERATED_DIR ]; then
    MANIFESTS_GENERATED_DIR="${HOME}/manifests/generated"
    CRDS_DIR="${HOME}/deploy/crds"
fi
MANIFESTS_GENERATED_CSV=${MANIFESTS_GENERATED_DIR}/kubevirt-ssp-operator.vVERSION.clusterserviceversion.yaml
TMP_FILE=$(mktemp)

replace_env_var() {
    local value_offset="                  "
    local key=$1
    local var=$2
    # Make sure to replace both valid YAML variants, structured and inline
    sed -i "s/- name: ${key}/- name: $1\n${value_offset}value: \"${var}\"/g" ${TMP_FILE}
    sed -i "s/{name: ${key}}/{name: $1, value: \"${var}\"}/g" ${TMP_FILE}
}

help_text() {
    echo "USAGE: csv-generator --csv-version=<version> --namespace=<namespace> --operator-image=<operator image> [optional args]"
    echo ""
    echo "ARGS:"
    echo "  --csv-version:    (REQUIRED) The version of the CSV file"
    echo "  --namespace:      (REQUIRED) The namespace set on the CSV file"
    echo "  --operator-image: (REQUIRED) The operator container image to use in the CSV file"
    echo "  --watch-namespace:   (OPTIONAL)"
    echo "  --validator-tag:     (OPTIONAL)"
    echo "  --image-name-prefix: (OPTIONAL)"
    echo "  --dump-crds:         (OPTIONAL) Dumps CRD manifests with the CSV to stdout"
}

# REQUIRED ARGS
CSV_VERSION=""
NAMESPACE=""
OPERATOR_IMAGE=""

# OPTIONAL ARGS
WATCH_NAMESPACE=""
VALIDATOR_TAG=""
IMAGE_NAME_PREFIX=""
DUMP_CRDS=""

while (( "$#" )); do
    ARG=`echo $1 | awk -F= '{print $1}'`
    VAL=`echo $1 | awk -F= '{print $2}'`
    shift

    case "$ARG" in
    --csv-version)
        CSV_VERSION=$VAL
        ;;
    --namespace)
        NAMESPACE=$VAL
        ;;
    --operator-image)
        OPERATOR_IMAGE=$VAL
        ;;
    --watch-namespace)
        WATCH_NAMESPACE=$VAL
        ;;
    --validator-tag)
        VALIDATOR_TAG=$VAL
        ;;
    --image-name-prefix)
        IMAGE_NAME_PREFIX=$VAL
        ;;
    --dump-crds)
        DUMP_CRDS="true"
        ;;
    --)
        break
        ;;
    *) # unsupported flag
        echo "Error: Unsupported flag $ARG" >&2
        exit 1
        ;;
    esac
done

if [ -z "$CSV_VERSION" ] || [ -z "$NAMESPACE" ] || [ -z "$OPERATOR_IMAGE" ]; then
    echo "Error: Missing required arguments"
    help_text
    exit 1
fi

cp ${MANIFESTS_GENERATED_CSV} ${TMP_FILE}

# replace placeholder version with a human readable variable name
# that will be used later on by csv-generator
sed -i "s/PLACEHOLDER_CSV_VERSION/${CSV_VERSION}/g" ${TMP_FILE}
sed -i "s/namespace: placeholder/namespace: ${NAMESPACE}/g" ${TMP_FILE}
sed -i "s|REPLACE_IMAGE|${OPERATOR_IMAGE}|g" ${TMP_FILE}

replace_env_var "WATCH_NAMESPACE" $WATCH_NAMESPACE
replace_env_var "VALIDATOR_TAG" $VALIDATOR_TAG
replace_env_var "IMAGE_NAME_PREFIX" $IMAGE_NAME_PREFIX

# dump CSV and CRD manifests to stdout
echo "---"
cat ${TMP_FILE}
rm ${TMP_FILE}
if [ "$DUMP_CRDS" = "true" ]; then
    for CRD in $( ls ${CRDS_DIR}/kubevirt_*crd.yaml ); do
        echo "---"
        cat ${CRD}
    done
fi
