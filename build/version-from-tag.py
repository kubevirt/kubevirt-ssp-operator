#!/usr/bin/env python

import sys

def _main():
    if len(sys.argv) != 2:
        sys.exit(1)
    tag = sys.argv[1]
    if tag.startswith('v'):
        print(tag[1:])
    else:
        print tag

if __name__ == "__main__":
    _main()
