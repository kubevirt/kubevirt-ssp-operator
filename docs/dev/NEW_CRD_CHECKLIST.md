### Adding a new CRD

1. create CRDs and CRs under `deploy/crds/`
2. if needed, fix RBAC rules under `deploy/`
3. add the role to handle the CRD
4. add watch and playbook to trigger the role
5. update the go client pkg
5.1. edited pkg/apis/kubevirt/v1/types.go
5.2. run ./build/generate.sh
6. edit `build/update-olm.py`
7. update `pgk/versions`
