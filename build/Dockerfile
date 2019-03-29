FROM quay.io/water-hole/ansible-operator

COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/
COPY watches.yaml ${HOME}/watches.yaml
COPY preprocessing.py ${HOME}/
COPY patch.yaml ${HOME}/
RUN python ${HOME}/preprocessing.py ${HOME}/patch.yaml ${HOME}/roles/KubevirtCommonTemplatesBundle/files/
