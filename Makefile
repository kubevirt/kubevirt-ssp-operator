# Always keep the future version here, so we won't overwrite latest released manifests
OPERATOR_SDK_VERSION ?= v0.19.2
OPERATOD_SDK_CSV_VERSION ?= v0.8.0

IMAGE_REGISTRY ?= quay.io/fromani
IMAGE_TAG ?= latest
OPERATOR_IMAGE ?= kubevirt-ssp-operator-container
REGISTRY_IMAGE ?= kubevirt-ssp-operator-registry

container-build: generate csv-generator
	docker build -f build/Dockerfile -t $(IMAGE_REGISTRY)/$(OPERATOR_IMAGE):$(IMAGE_TAG) .

container-push:
	docker push $(IMAGE_REGISTRY)/$(OPERATOR_IMAGE):$(IMAGE_TAG)

csv-generator: operator-sdk-csv
	./build/make-csv-generator.sh

operator-sdk:
	curl -JL https://github.com/operator-framework/operator-sdk/releases/download/$(OPERATOR_SDK_VERSION)/operator-sdk-$(OPERATOR_SDK_VERSION)-x86_64-linux-gnu -o operator-sdk
	chmod 0755 operator-sdk

operator-sdk-csv:
	curl -JL https://github.com/operator-framework/operator-sdk/releases/download/$(OPERATOD_SDK_CSV_VERSION)/operator-sdk-$(OPERATOD_SDK_CSV_VERSION)-x86_64-linux-gnu -o operator-sdk-csv
	chmod 0755 operator-sdk-csv

manifests-prepare:
	mkdir -p _out/olm-catalog

manifests-cleanup:
	rm -rf _out

generate-crds: operator-sdk
	./operator-sdk generate crds

generate: generate-crds csv-generator

manifests: manifests-cleanup manifests-prepare csv-generator
	./hack/make-manifests.sh ${IMAGE_REGISTRY}/${OPERATOR_IMAGE}:${IMAGE_TAG}

deploy: manifests
	./hack/deploy-operator.sh

release: manifests container-build

functests:
	cd functests && ./test-runner.sh

# OCP CI specific targets
# This target is used to create manifests for Openshift CI clsuters (presubmit jobs)
# IMAGE_FORMAT environment variable contains the container registry of the build image 
# like so: 'registry.svc.ci.openshift.org/ci-op-qr0i5qnz/stable:$component' then the tag of that
# image should be the image name of our operator.
ocp-ci-manifests: operator-sdk manifests-cleanup manifests-prepare
	./operator-sdk generate crds
	component=$(OPERATOR_IMAGE) ./hack/make-ocp-ci-manifests.sh $(IMAGE_FORMAT)$(OPERATOR_IMAGE)

ocp-ci-deploy: ocp-ci-manifests
	./hack/deploy-operator.sh

.PHONY: functests release manifests manifests-prepare manifests-cleanup container-build deploy generate generate-crds ocp-ci-manifests ocp-ci-deploy
