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

To avoid incurring in the github API throttling, if you have a [github personal access token](https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line),
you should set it now, by doing something like
```bash
export GITHUB_TOKEN=...
```

Now, run in your repo:

```bash
hack/install-operator.sh $NAMESPACE
```

## Generate the YAML manifests

The generation process requires the [operator SDK](https://github.com/operator-framework/operator-sdk) binary.
If present in your path, the process will use that, otherwise it will be downloaded from the release channel.
To regenerate the manifests, do in your repo:
```bash
make manifests
```
Find the manifests in the `_out` directory once done.

## Functional tests

We use [traviskube](https://gitihub.com/fromanirh/traviskube) to integrate the functional tests on travis.
Make sure you initialize the submodules. In your repo:
```bash
git submodule init
```

To run the functional tests, you will need access to a OKD cluster. The travis script set up from scratch
a minishift environment to run the tests into.

Once the environment is set up, you can run the tests by doing, in your repo:
```bash
make functests
```
