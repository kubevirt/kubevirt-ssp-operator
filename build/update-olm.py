#!/usr/bin/env python3

import logging
import sys
import yaml


_DESCRIPTION = "KubeVirt Schedule, Scale and Performance Operator"
_NAMESPACE = 'kubevirt'
_SPEC = {
    'provider': {
        'name': 'KubeVirt project'
    },
    'maintainers': [{
        'name': 'KubeVirt project',
        'email': 'kubevirt-dev@googlegroups.com',
    }],
    'keywords': [
        'KubeVirt', 'Virtualization', 'Template', 'Performance',
        'VirtualMachine'
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
        'alm-owner-kubevirt': 'kubevirtsspoperator',
        'operated-by': 'kubevirtsspoperator',
    },
    # TODO: unsure about this, following what others do
    'selector': {
        'matchLabels': {
            'alm-owner-kubevirt': 'kubevirtsspoperator',
            'operated-by': 'kubevirtsspoperator',
        },
    },
}


def process(path):
    with open(path, 'rt') as fh:
        manifest = yaml.safe_load(fh)

    manifest['spec'].update(_SPEC)
    manifest['metadata']['namespace'] = _NAMESPACE
    manifest['spec']['description'] = _DESCRIPTION

    yaml.safe_dump(manifest, sys.stdout)


if __name__ == '__main__':
    for arg in sys.argv[1:]:
        try:
            process(arg)
        except Exception as ex:
            logging.error('error processing %r: %s', arg, ex)
            # keep going!
