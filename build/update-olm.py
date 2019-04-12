#!/usr/bin/env python3

import logging
import sys
import yaml


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
}


def process(path):
    with open(path, 'rt') as fh:
        manifest = yaml.safe_load(fh)

    manifest['spec'].update(_SPEC)

    with open(path, 'wt') as fh:
        yaml.safe_dump(manifest, fh)


if __name__ == '__main__':
    for arg in sys.argv[1:]:
        try:
            process(arg)
        except Exception as ex:
            logging.error('error processing %r: %s', arg, ex)
            # keep going!
        else:
            print('INFO[0000] Updated with SSP spec: %r' % arg)
