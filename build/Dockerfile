FROM quay.io/operator-framework/ansible-operator:v0.7.0

COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/
COPY watches.yaml ${HOME}/watches.yaml
COPY _defaults.yml ${HOME}/_defaults.yml

COPY build/preprocess_template.pyc ${HOME}/
COPY patch.yaml ${HOME}/
RUN python ${HOME}/preprocess_template.pyc ${HOME}/patch.yaml ${HOME}/roles/KubevirtCommonTemplatesBundle/files/
