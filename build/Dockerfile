FROM quay.io/operator-framework/ansible-operator:v0.15.2

LABEL org.kubevirt.hco.csv-generator.v1="/usr/bin/csv-generator"

COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/
COPY watches.yaml ${HOME}/watches.yaml
COPY _defaults.yml ${HOME}/_defaults.yml

COPY deploy/crds ${HOME}/deploy/crds
COPY manifests/generated ${HOME}/manifests/generated
COPY build/csv-generator.sh /usr/bin/csv-generator

COPY build/preprocess_template.py ${HOME}/
COPY patch.yaml ${HOME}/
RUN python3 ${HOME}/preprocess_template.py ${HOME}/patch.yaml ${HOME}/roles/KubevirtCommonTemplatesBundle/files/
