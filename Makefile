# Always keep the future version here, so we won't overwrite latest released manifests

IMAGE_REGISTRY ?= quay.io/fromani
IMAGE_TAG ?= latest
OPERATOR_IMAGE ?= kubevirt-ssp-operator-container
REGISTRY_IMAGE ?= kubevirt-ssp-operator-registry

container-build: container-build-operator container-build-registry

container-build-operator:
	docker build -f build/Dockerfile -t $(IMAGE_REGISTRY)/$(OPERATOR_IMAGE):$(IMAGE_TAG) .

container-build-registry:
	docker build -f build/Dockerfile.registry -t $(IMAGE_REGISTRY)/$(REGISTRY_IMAGE):$(IMAGE_TAG) .

container-push: container-push-operator container-push-registry

container-push-operator:
	docker push $(IMAGE_REGISTRY)/$(OPERATOR_IMAGE):$(IMAGE_TAG)

container-push-registry:
	docker push $(IMAGE_REGISTRY)/$(REGISTRY_IMAGE):$(IMAGE_TAG)

functests:
	cd functests && ./test-runner.sh

.PHONY: functests
