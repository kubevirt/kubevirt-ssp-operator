FROM quay.io/water-hole/ansible-operator

COPY preprocess_template.py ${HOME}/
COPY test_preprocess_template.py ${HOME}/
RUN python ${HOME}/test_preprocess_template.py

COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/
COPY watches.yaml ${HOME}/watches.yaml
COPY patch.yaml ${HOME}/

RUN python ${HOME}/preprocess_template.py ${HOME}/patch.yaml ${HOME}/roles/KubevirtCommonTemplatesBundle/files/
