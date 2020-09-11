#!/usr/bin/env python3

import logging
import sys
import yaml


_ANNOTATIONS = {
    'categories': 'Openshift Optional',
    'description': \
        'Manages KubeVirt addons for Scheduling, Scale, Performance',
    'containerImage': 'REPLACE_IMAGE',
}
_DESCRIPTION = "KubeVirt Schedule, Scale and Performance Operator"
_NAMESPACE = 'kubevirt'
_SPEC = {
    'description': _DESCRIPTION,
    'provider': {
        'name': 'KubeVirt project'
    },
    'maintainers': [{
        'name': 'KubeVirt project',
        'email': 'kubevirt-dev@googlegroups.com',
    }],
    'keywords': [
        'KubeVirt', 'Virtualization', 'Template', 'Performance',
        'VirtualMachine', 'Node', 'Labels',
    ],
    # TODO: icon?
    'links': [{
        'name': 'KubeVirt',
        'url': 'https://kubevirt.io',
    }, {
        'name': 'Source Code',
        'url': 'https://github.com/kubevirt/kubevirt'
    }],
    # TODO: unsure about this, following what others do
    'labels': {
        'alm-owner-kubevirt': 'kubevirt-ssp-operator',
        'operated-by': 'kubevirt-ssp-operator',
    },
    # TODO: unsure about this, following what others do
    'selector': {
        'matchLabels': {
            'alm-owner-kubevirt': 'kubevirt-ssp-operator',
            'operated-by': 'kubevirt-ssp-operator',
        },
    },
}

_CRD_INFOS = {
    'kubevirttemplatevalidators.ssp.kubevirt.io': {
        'displayName': 'KubeVirt Template Validator admission webhook',
        'description': \
                'Represents a deployment of admission control webhook to validate the KubeVirt templates',
        'specDescriptors': [{
            'description': \
                'The version of the KubeVirt Template Validator to deploy',
            'displayName': 'Version',
            'path': 'version',
            'version': 'v1',
            'x-descriptors': [
                'urn:alm:descriptor:io.kubernetes.ssp:version',
            ],
        }],
    },
    'kubevirtcommontemplatesbundles.ssp.kubevirt.io': {
        'displayName': 'KubeVirt common templates',
        'description': \
                'Represents a deployment of the predefined VM templates',
        'specDescriptors': [{
            'description': \
                'The version of the KubeVirt Templates to deploy',
            'displayName': 'Version',
            'path': 'version',
            'version': 'v1',
            'x-descriptors': [
                'urn:alm:descriptor:io.kubernetes.ssp:version',
            ],
        }],
    },
    'kubevirtnodelabellerbundles.ssp.kubevirt.io': {
        'displayName': 'KubeVirt Node labeller',
        'description': \
                'Represents a deployment of Node labeller component',
        'specDescriptors': [{
            'description': \
                'The version of the node labeller to deploy',
            'displayName': 'Version',
            'path': 'version',
            'version': 'v1',
            'x-descriptors': [
                'urn:alm:descriptor:io.kubernetes.ssp:version',
            ],
        }],
    },
    'kubevirtmetricsaggregations.ssp.kubevirt.io': {
        'displayName': 'KubeVirt Metric Aggregation',
        'description': \
                'Provide aggregation rules for core kubevirt metrics',
        'specDescriptors': [{
            'description': \
                'The version of the aggregation rules to deploy',
            'displayName': 'Version',
            'path': 'version',
            'version': 'v1',
            'x-descriptors': [
                'urn:alm:descriptor:io.kubernetes.ssp:version',
            ],
        }],
    },
}


def process(path):
    with open(path, 'rt') as fh:
        manifest = yaml.safe_load(fh)

    manifest['metadata']['namespace'] = _NAMESPACE
    manifest['metadata']['annotations'].update(_ANNOTATIONS)

    manifest['spec'].update(_SPEC)

    for crd in manifest['spec']['customresourcedefinitions']['owned']:
        crd.update(_CRD_INFOS.get(crd['name'], {}))

    yaml.safe_dump(manifest, sys.stdout)


if __name__ == '__main__':
    for arg in sys.argv[1:]:
        try:
            process(arg)
        except Exception as ex:
            logging.error('error processing %r: %s', arg, ex)
            # keep going!
