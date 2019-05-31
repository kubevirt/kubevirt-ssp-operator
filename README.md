# kubevirt-ssp-operator
Operator that manages Scheduling, Scale and Performance addons for [KubeVirt](https://kubevirt.io)

## Prerequisites

- Golang environment and GOPATH correctly set
- Docker (used for creating container images, etc.) with access for the current user
- a Kubernetes/OpenShift/Minikube/Minishift instance
- [Operator SDK](https://github.com/operator-framework/operator-sdk)

## Installation instructions

The `kubevirt-ssp-operator` requires a Openshift cluster to run properly.
Installation on vanilla kubernetes is technically possible, but many features will not work, so this option
is unsupported.

### Using [HCO](https://github.com/kubevirt/hyperconverged-cluster-operator)

The [Hyperconverged Cluster Operator](https://github.com/kubevirt/hyperconverged-cluster-operator) automatically
installs the SSP operator when deploying. So you can just install the HCO on your openshift cluster.

### Manual installation steps

We assume you install the kubevirt-ssp-operator AFTER that [kubevirt](https://kubevirt.io) is succesfully deployed on the same cluster.

You can install the `kubevirt-ssp-operator` using the provided manifests.

Assuming you work from the operator source tree root:
```bash
cd kubevirt-ssp-operator
```

Select the namespace you want to install the operator into. If unsure, the `kubevirt` namespace is a safe choice:
```bash
export NAMESPACE=kubevirt
```

```bash
oc create -n ${NAMESPACE} -f deploy/service_account.yaml
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:${NAMESPACE}:kubevirt-ssp-operator
oc create -n ${NAMESPACE} -f deploy/role.yaml
oc create -n ${NAMESPACE} -f deploy/role_binding.yaml
oc create -n ${NAMESPACE} -f deploy/operator.yaml
```

The `hack/install-operator.sh` automates the above steps for you. Run it from the operator source tree root.
Usage:
```bash
hack/install-operor.sh $NAMESPACE
```
