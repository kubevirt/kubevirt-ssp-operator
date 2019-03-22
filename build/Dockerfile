FROM quay.io/water-hole/ansible-operator

USER 0
COPY repos/RPM-GPG-KEY-CentOS-SIG-PaaS /etc/pki/rpm-gpg
COPY repos/centos-openshift-origin.repo /etc/yum.repos.d
RUN yum install -y openssl origin-clients
USER 1001

COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/
COPY watches.yaml ${HOME}/watches.yaml
