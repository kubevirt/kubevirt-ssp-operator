# kubevirt-ssp-operator troubleshooting

This document contains the most common issues reported when running the `kubevirt-ssp-operator`
and their solutions.

## Emergency disable

Starting version 1.0.14, the SSP operator supports emergency disable of the operands it manages.
To engage this feature, you need to set the `kubevirt.io/operator.paused` annotation to `true` in the CR you want to disable.
Add the key if missing.

Example:
```yaml
apiVersion: kubevirt.io/v1
kind: KubevirtTemplateValidator
metadata:
  name: kubevirt-template-validator
  namespace: kubevirt
  annotations:
    kubevirt.io/operator.paused: "true"
spec:
  version: v0.6.2
```

To restore the functionality, set the annotation to `false`, or delete the value entirely.
Currently only the `template-validator` CR supports this functionality.

## Openshift 3.11

### error: "cannot create clusterroles.rbac.authorization.k8s.io at the cluster scope"
Platform: Openshift origin 3.11 installed using "oc cluster up" as per quickstart

Make sure first [you set the proper permissions for kubevirt](https://kubevirt.io/user-guide/docs/latest/administration/intro.html#deploying-on-openshift)

Make sure the operator account has the `cluster-admin` cluster role
```bash
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:kubevirt:kubevirt-ssp-operator
```
