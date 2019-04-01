# kubevirt-ssp-operator troubleshooting

This document contains the most common issues reported when running the `kubevirt-ssp-operator`
and their solutions.

## Openshift 3.11

### error: "cannot create clusterroles.rbac.authorization.k8s.io at the cluster scope"
Platform: Openshift origin 3.11 installed using "oc cluster up" as per quickstart

Make sure first [you set the proper permissions for kubevirt](https://kubevirt.io/user-guide/docs/latest/administration/intro.html#deploying-on-openshift)

Make sure the operator account has the `cluster-admin` cluster role
```bash
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:kubevirt:kubevirt-ssp-operator
```
