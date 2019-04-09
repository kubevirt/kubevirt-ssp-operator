FROM quay.io/water-hole/ansible-operator

COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/
COPY watches.yaml ${HOME}/watches.yaml
COPY build/preprocess_template.py ${HOME}/
COPY build/patch.yaml ${HOME}/

RUN python ${HOME}/preprocess_template.py ${HOME}/patch.yaml ${HOME}/roles/KubevirtCommonTemplatesBundle/files/
