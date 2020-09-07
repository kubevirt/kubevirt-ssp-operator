#!/bin/bash
set -e

SELF=$( realpath $0 )
BASEPATH=$( dirname $SELF )

./operator-sdk generate crds

crd_files=$(ls deploy/crds/*crd.yaml)

for crd in $crd_files
do
  echo "  preserveUnknownFields: false" >> $crd
done
