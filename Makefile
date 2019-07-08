# Always keep the future version here, so we won't overwrite latest released manifests

OPERATOR_SDK_VERSION ?= v0.8.0
IMAGE_REGISTRY ?= quay.io/fromani
IMAGE_TAG ?= latest
OPERATOR_IMAGE ?= kubevirt-ssp-operator-container
REGISTRY_IMAGE ?= kubevirt-ssp-operator-registry

container-build: container-build-operator container-build-registry

container-build-operator:
	python -m compileall build/preprocess_template.py
	docker build -f build/Dockerfile -t $(IMAGE_REGISTRY)/$(OPERATOR_IMAGE):$(IMAGE_TAG) .
	rm -f build/preprocess_template.pyc

container-build-registry:
	docker build -f build/Dockerfile.registry -t $(IMAGE_REGISTRY)/$(REGISTRY_IMAGE):$(IMAGE_TAG) .

container-push: container-push-operator container-push-registry

container-push-operator:
	docker push $(IMAGE_REGISTRY)/$(OPERATOR_IMAGE):$(IMAGE_TAG)

container-push-registry:
	docker push $(IMAGE_REGISTRY)/$(REGISTRY_IMAGE):$(IMAGE_TAG)

container-release:
	./hack/docker-push.sh $(IMAGE_REGISTRY)/$(OPERATOR_IMAGE):$(IMAGE_TAG) $(IMAGE_REGISTRY)/$(REGISTRY_IMAGE):$(IMAGE_TAG)

operator-sdk:
	curl -JL https://github.com/operator-framework/operator-sdk/releases/download/$(OPERATOR_SDK_VERSION)/operator-sdk-$(OPERATOR_SDK_VERSION)-x86_64-linux-gnu -o operator-sdk
	chmod 0755 operator-sdk

manifests-prepare:
	mkdir -p _out

manifests-cleanup:
	rm -rf _out

manifests: manifests-cleanup manifests-prepare operator-sdk
	./build/make-manifests.sh ${IMAGE_TAG}
	./hack/release-manifests.sh ${IMAGE_TAG}

release: manifests container-build container-release

functests:
	cd functests && ./test-runner.sh

.PHONY: functests release manifests manifests-prepare manifests-cleanup container-push container-build container-release
