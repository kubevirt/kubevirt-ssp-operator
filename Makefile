# Always keep the future version here, so we won't overwrite latest released manifests

OPERATOR_SDK_VERSION ?= v0.8.0
IMAGE_REGISTRY ?= quay.io/fromani
IMAGE_TAG ?= latest
OPERATOR_IMAGE ?= kubevirt-ssp-operator-container
REGISTRY_IMAGE ?= kubevirt-ssp-operator-registry

container-build: csv-generator container-build-operator container-build-registry

container-build-operator:
	docker build -f build/Dockerfile -t $(IMAGE_REGISTRY)/$(OPERATOR_IMAGE):$(IMAGE_TAG) .

container-build-registry:
	docker build -f build/Dockerfile.registry -t $(IMAGE_REGISTRY)/$(REGISTRY_IMAGE):$(IMAGE_TAG) .

container-push: container-push-operator container-push-registry

container-push-operator:
	docker push $(IMAGE_REGISTRY)/$(OPERATOR_IMAGE):$(IMAGE_TAG)

container-push-registry:
	docker push $(IMAGE_REGISTRY)/$(REGISTRY_IMAGE):$(IMAGE_TAG)

container-release:
	./hack/docker-push.sh $(IMAGE_REGISTRY)/$(OPERATOR_IMAGE):$(IMAGE_TAG) $(IMAGE_REGISTRY)/$(REGISTRY_IMAGE):$(IMAGE_TAG)

csv-generator: operator-sdk
	./build/make-csv-generator.sh

operator-sdk:
	curl -JL https://github.com/operator-framework/operator-sdk/releases/download/$(OPERATOR_SDK_VERSION)/operator-sdk-$(OPERATOR_SDK_VERSION)-x86_64-linux-gnu -o operator-sdk
	chmod 0755 operator-sdk

operator-courier:
	pip3 install --user operator-courier

manifests-prepare:
	mkdir -p _out

manifests-cleanup:
	rm -rf _out

manifests: operator-courier csv-generator manifests-cleanup manifests-prepare operator-sdk
	./hack/make-manifests.sh ${IMAGE_REGISTRY}/${OPERATOR_IMAGE}:${IMAGE_TAG}
	./hack/release-manifests.sh ${IMAGE_TAG}

deploy: manifests
	./hack/deploy-operator.sh

release: manifests container-build container-release

functests:
	cd functests && ./test-runner.sh

# OCP CI specific targets
# This target is used to create manifests for Openshift CI clsuters (presubmit jobs)
# IMAGE_FORMAT environment variable contains the container registry of the build image 
# like so: 'registry.svc.ci.openshift.org/ci-op-qr0i5qnz/stable:' then the tag of that
# image should be the image name of our operator.
ocp-ci-manifests: manifests-cleanup manifests-prepare
	component=$(OPERATOR_IMAGE) ./hack/make-ocp-ci-manifests.sh $(IMAGE_FORMAT)$(OPERATOR_IMAGE)

ocp-ci-deploy: ocp-ci-manifests
	./hack/deploy-operator.sh

.PHONY: functests release manifests manifests-prepare manifests-cleanup container-push container-build container-release deploy ocp-ci-manifests ocp-ci-deploy
