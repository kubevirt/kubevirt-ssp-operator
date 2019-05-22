# kubevirt-ssp-operator functional tests

*WARNING*: work in progress. We are still working to make the tests more automated and more robust.

## Preparation
1. install OKD >= 3.11
2. install kubevirt >= 0.17
4. install the SSP operator
3. ready!

## Warning about [HCO](https://github.com/kubevirt/hyperconverged-cluster-operator)

The HCO installation flow will chain-create the low-level SSP CRs that these tests want to exercise.
This may likely void functional tests.

## run the tests
```bash
./test-runner.sh
```
