FROM quay.io/operator-framework/ansible-operator

COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/
COPY watches.yaml ${HOME}/watches.yaml
COPY _defaults.yml ${HOME}/_defaults.yml

COPY build/preprocess_template.py ${HOME}/
COPY patch.yaml ${HOME}/
RUN python ${HOME}/preprocess_template.py ${HOME}/patch.yaml ${HOME}/roles/KubevirtCommonTemplatesBundle/files/
