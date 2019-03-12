Kubevirt Scheduling, Scale and Performance operator
=========

This operator is responsible for maintaining the kubevirt components
needed for scheduling, scale and performance of VMs.

Such as:

- VM templates and related infrastructure,
- metrics collectors,
- node feature discovery plugins,
- scheduler extensions,
- and anything related to those.

Requirements
------------

Any pre-requisites that may not be covered by Ansible itself or the role should be mentioned here. For instance, if the role uses the EC2 module, it may be a good idea to mention in this section that the boto package is required.

Role Variables
--------------

The only mandatory variable that should be set by the custom resource is the
expected `version` of the managed components.

Dependencies
------------

The operator depends on (Node feature discovery)[https://github.com/kubernetes-sigs/node-feature-discovery] that should be provided using
its own operator: https://github.com/openshift/cluster-nfd-operator

Example Playbook
----------------

    - hosts: servers
      roles:
         - { role: KubevirtCommonTemplatesBundle, version: "v0.4.2" }

License
-------

Apache License V2.0

Author Information
------------------

Red Hat, 2018

