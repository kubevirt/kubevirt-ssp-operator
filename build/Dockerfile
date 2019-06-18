FROM quay.io/operator-framework/ansible-operator:v0.7.0

USER 0
COPY repos/RPM-GPG-KEY-CentOS-SIG-PaaS /etc/pki/rpm-gpg
COPY repos/centos-openshift-origin.repo /etc/yum.repos.d
RUN yum install -y origin-clients
RUN yum clean all
USER 1001

COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/
COPY watches.yaml ${HOME}/watches.yaml
COPY _defaults.yml ${HOME}/_defaults.yml

COPY build/preprocess_template.py ${HOME}/
COPY patch.yaml ${HOME}/
RUN python ${HOME}/preprocess_template.py ${HOME}/patch.yaml ${HOME}/roles/KubevirtCommonTemplatesBundle/files/
