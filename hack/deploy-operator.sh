#!/bin/bash

oc apply -f _out/kubevirt-ssp-operator-crd.yaml
oc apply -f _out/kubevirt-ssp-operator-cr.yaml
oc apply -f _out/kubevirt-ssp-operator.yaml
