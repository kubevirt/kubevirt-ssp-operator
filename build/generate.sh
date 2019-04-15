#!/bin/bash
./vendor/k8s.io/code-generator/generate-groups.sh \
	all \
	github.com/MarSik/kubevirt-ssp-operator/pkg/client \
	github.com/MarSik/kubevirt-ssp-operator/pkg/apis \
	kubevirt:v1
