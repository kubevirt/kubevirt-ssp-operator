#!/bin/sh
oc delete ValidatingWebhookConfiguration virt-template-validator
oc delete svc -n kubevirt virt-template-validator
oc delete deployment -n kubevirt virt-template-validator
oc delete secret -n kubevirt virt-template-validator-certs
oc delete crd kubevirttemplatevalidators.kubevirt.io
oc delete clusterrole template:view
