FROM quay.io/operator-framework/ansible-operator:v0.16.0

LABEL org.kubevirt.hco.csv-generator.v1="/usr/bin/csv-generator"

COPY build/release/ansible/ansible_collections ${HOME}/.ansible/collections/ansible_collections
COPY build/release/ansible/update-collections.sh ${HOME}/.ansible/
RUN ${HOME}/.ansible/update-collections.sh operator_sdk.util
 
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

COPY cmd/webhook-updater/webhook-updater /usr/bin/webhook-updater
