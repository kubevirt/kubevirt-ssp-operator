#!/bin/bash

SCRIPTPATH=$(dirname $(readlink -f $0))
source ${SCRIPTPATH}/testlib.sh

TEST_NS="kubevirt-os-images"
EDIT_ROLE="os-images.kubevirt.io:edit"
VIEW_ROLE="os-images.kubevirt.io:view"
TEST_SA="testsa"
TEST_SA_NS="test-sa-ns"

find_namespace() {
  # Find if the new namespace is created

  local wait_secs=${1:-2}
  local max_tries=${2:-20}

  for idx in $(seq 1 ${max_tries}); do
    ((${V} >= 1)) && echo "Attempt ${idx}/${max_tries} to find namespace ${TEST_NS}"
    oc get ns ${TEST_NS}
    if [ $? == 0 ]; then
      ((${V} >= 1)) && echo "Found Namespace in Attempt ${idx}"
      return 0
    fi
    sleep ${wait_secs}s
  done
  return 1
}

find_editclusterrole() {
  # Find if the Edit Clusterrole is created

  local wait_secs=${1:-2}
  local max_tries=${2:-15}

  for idx in $(seq 1 ${max_tries}); do
    ((${V} >= 1)) && echo "Attempt ${idx}/${max_tries} to find edit clusterrole ${EDIT_ROLE}"
    oc get clusterrole ${EDIT_ROLE}
    if [ $? == 0 ]; then
      ((${V} >= 1)) && echo "Found edit clusterrole in Attempt ${idx}"
      return 0
    fi
    sleep ${wait_secs}s
  done
  return 1
}

find_viewrole() {
  # Find if the View Role is created

  local wait_secs=${1:-2}
  local max_tries=${2:-15}

  for idx in $(seq 1 ${max_tries}); do
    ((${V} >= 1)) && echo "Attempt ${idx}/${max_tries} to find view role ${VIEW_ROLE}"
    oc get role ${VIEW_ROLE} -n ${TEST_NS}
    if [ $? == 0 ]; then
      ((${V} >= 1)) && echo "Found view role in Attempt ${idx}"
      return 0
    fi
    sleep ${wait_secs}s
  done
  return 1
}

find_viewrolebinding() {
  # Find if the View Rolebinding is created

  local wait_secs=${1:-2}
  local max_tries=${2:-15}

  for idx in $(seq 1 ${max_tries}); do
    ((${V} >= 1)) && echo "Attempt ${idx}/${max_tries} to find view rolebinding ${VIEW_ROLE}"
    oc get rolebinding ${VIEW_ROLE} -n ${TEST_NS}
    if [ $? == 0 ]; then
      ((${V} >= 1)) && echo "Found view rolebinding in Attempt ${idx}"
      return 0
    fi
    sleep ${wait_secs}s
  done
  return 1
}

quit_cleanup() {
  if [ $1 -eq 1 ]; then
    oc delete -n ${SSP_OP_POD_NAMESPACE} -f "${SCRIPTPATH}/common-templates-unversioned-cr.yaml"
    oc delete clusterrole ${EDIT_ROLE}
    oc delete ns ${TEST_NS}
    oc delete ns ${TEST_SA_NS}
    exit $1
  fi
}

trap 'quit_cleanup $?' EXIT

# Create the CR and wait for it be "Ready"
oc create -n ${SSP_OP_POD_NAMESPACE} -f "${SCRIPTPATH}/common-templates-unversioned-cr.yaml" || exit 2
wait_for_deployment_ready ${SSP_OP_POD_NAMESPACE} 5 10 "KubevirtCommonTemplatesBundle" "Running" "Successful" || exit

# Check if the namespace is created
echo "[test_id:4494]: OS Images namespace is created"
find_namespace || exit

# Check if the edit clusterrole is created
echo "[test_id:4584]: Edit Clusterrole is created"
find_editclusterrole || exit

# Check if view role is created
echo "[test_id:4777]: View Role is created"
find_viewrole || exit

# Check if view rolebinding is created
echo "[test_id:4772]: View Rolebinding is created"
find_viewrolebinding || exit

# Check if the role, rolebinding, clusterrole and namespace are recreated upon deletion
oc delete clusterrole ${EDIT_ROLE} || exit
oc delete ns ${TEST_NS} || exit

# Check if the namespace is re-created
echo "[test_id:4770]: OS Images namespace is re-created after deletion"
find_namespace || exit

# Check if the edit clusterrole is re-created
echo "[test_id:4771]: Edit Clusterrole is re-created after deletion"
find_editclusterrole || exit

# Check if view role is re-created
echo "[test_id:4773]: View Role is re-created after deletion"
find_viewrole || exit

# Check if view rolebinding is re-created
echo "[test_id:4842]: View Rolebinding is re-created after deletion"
find_viewrolebinding || exit

# Verify ServiceAccount with view role can view PVCs
echo "[test_id:4775]: ServiceAccounts with view role can view PVCs"
((${V} >= 1)) && echo "Create a test service account : ${TEST_SA}"
oc create ns ${TEST_SA_NS} || exit
oc create sa ${TEST_SA} -n ${TEST_SA_NS} || exit
oc auth can-i get pvc --as system:serviceaccount:${TEST_SA_NS}:${TEST_SA} -n ${TEST_NS} || exit
((${V} >= 1)) && echo "Service Account ${TEST_SA} is able to view PVCs in namespace ${TEST_NS}"

# Verify ServiceAccount with only view role cannot create PVCs
echo "[test_id:4776]: ServiceAccounts with only view role cannot create PVCs"
oc auth can-i create pvc --as system:serviceaccount:${TEST_SA_NS}:${TEST_SA} -n ${TEST_NS}
if [ $? == 0 ]; then
  quit_cleanup 1
fi
((${V} >= 1)) && echo "Service Account ${TEST_SA} is unable to create PVCs in namespace ${TEST_NS}"

# Verify ServiceAccount with only view role cannot delete PVCs
echo "[test_id:4846]: ServiceAccounts with only view role cannot delete PVCs"
oc auth can-i delete pvc --as system:serviceaccount:${TEST_SA_NS}:${TEST_SA} -n ${TEST_NS}
if [ $? == 0 ]; then
  quit_cleanup 1
fi
((${V} >= 1)) && echo "Service Account ${TEST_SA} is unable to delete PVCs in namespace ${TEST_NS}"

# Verify ServiceAccount with only view role cannot view DVs
echo "[test_id:4875]: ServiceAccounts with only view role cannot view DVs"
oc auth can-i get dv --as system:serviceaccount:${TEST_SA_NS}:${TEST_SA} -n ${TEST_NS}
if [ $? == 0 ]; then
  quit_cleanup 1
fi
((${V} >= 1)) && echo "Service Account ${TEST_SA} is unable to view DVs in namespace ${TEST_NS}"

# Verify ServiceAccount with only view role cannot create DVs
echo "[test_id:4874]: ServiceAccounts with only view role cannot create DVs"
oc auth can-i create dv --as system:serviceaccount:${TEST_SA_NS}:${TEST_SA} -n ${TEST_NS}
if [ $? == 0 ]; then
  quit_cleanup 1
fi
((${V} >= 1)) && echo "Service Account ${TEST_SA} is unable to create DVs in namespace ${TEST_NS}"

# Verify ServiceAccount with only view role can create dv/source
echo "[test_id:5005]: ServiceAccounts with only view role can create dv/source"
oc auth can-i create dv --subresource=source --as system:serviceaccount:${TEST_SA_NS}:${TEST_SA} -n ${TEST_NS} || exit
((${V} >= 1)) && echo "Service Account ${TEST_SA} is able to create dv/source in namespace ${TEST_NS}"

# Verify ServiceAccount with only view role cannot delete DVs
echo "[test_id:4873]: ServiceAccounts with only view role cannot delete DVs"
oc auth can-i delete dv --as system:serviceaccount:${TEST_SA_NS}:${TEST_SA} -n ${TEST_NS}
if [ $? == 0 ]; then
  quit_cleanup 1
fi
((${V} >= 1)) && echo "Service Account ${TEST_SA} is unable to delete DVs in namespace ${TEST_NS}"

# Verify ServiceAccount with only view role cannot create any other resurces other than the ones listed in the Viewrole
echo "[test_id:4879]: ServiceAccounts with only view role cannot create any other resurces other than the ones listed in the Viewrole"
oc auth can-i create pods --as system:serviceaccount:${TEST_SA_NS}:${TEST_SA} -n ${TEST_NS}
if [ $? == 0 ]; then
  quit_cleanup 1
fi
((${V} >= 1)) && echo "Service Account ${TEST_SA} is unable to create pods in namespace ${TEST_NS}"

# Verify ServiceAccount with edit role can create PVCs
echo "[test_id:4774]: ServiceAcounts with edit role can create PVCs"
((${V} >= 1)) && echo "Create a edit rolebinding for service account : ${TEST_SA}"
oc create rolebinding testeditimage --clusterrole ${EDIT_ROLE} --serviceaccount ${TEST_SA_NS}:${TEST_SA} -n ${TEST_NS} || exit
oc auth can-i create pvc --as system:serviceaccount:${TEST_SA_NS}:${TEST_SA} -n ${TEST_NS} || exit
((${V} >= 1)) && echo "Service Account ${TEST_SA} is able to create PVCs in namespace ${TEST_NS}"

# Verify ServiceAccount with edit role can delete PVCs
echo "[test_id:4845]: ServiceAcounts with edit role can delete PVCs"
oc auth can-i delete pvc --as system:serviceaccount:${TEST_SA_NS}:${TEST_SA} -n ${TEST_NS} || exit
((${V} >= 1)) && echo "Service Account ${TEST_SA} is able to delete PVCs in namespace ${TEST_NS}"

# Verify ServiceAccount with edit role can view DVs
echo "[test_id:4877]: ServiceAccounts with edit role can view DVs"
oc auth can-i get dv --as system:serviceaccount:${TEST_SA_NS}:${TEST_SA} -n ${TEST_NS} || exit
((${V} >= 1)) && echo "Service Account ${TEST_SA} is able to view DVs in namespace ${TEST_NS}"

# Verify ServiceAccount with edit role can create DVs
echo "[test_id:4872]: ServiceAcounts with edit role can create DVs"
oc auth can-i create dv --as system:serviceaccount:${TEST_SA_NS}:${TEST_SA} -n ${TEST_NS} || exit
((${V} >= 1)) && echo "Service Account ${TEST_SA} is able to create DVs in namespace ${TEST_NS}"

# Verify ServiceAccount with edit role can delete DVs
echo "[test_id:4876]: ServiceAcounts with edit role can delete DVs"
oc auth can-i delete dv --as system:serviceaccount:${TEST_SA_NS}:${TEST_SA} -n ${TEST_NS} || exit
((${V} >= 1)) && echo "Service Account ${TEST_SA} is able to delete DVs in namespace ${TEST_NS}"

# Verify ServiceAccount with edit role cannot create any other resurces other than the ones listed in the Edit role
echo "[test_id:4878]: ServiceAccounts with edit role cannot create any other resurces other than the ones listed in the Edit Cluster role"
oc auth can-i create pods --as system:serviceaccount:${TEST_SA_NS}:${TEST_SA} -n ${TEST_NS}
if [ $? == 0 ]; then
  quit_cleanup 1
fi
((${V} >= 1)) && echo "Service Account ${TEST_SA} is unable to create pods in namespace ${TEST_NS}"

oc delete -n ${SSP_OP_POD_NAMESPACE} -f "${SCRIPTPATH}/common-templates-unversioned-cr.yaml" || exit
oc delete clusterrole ${EDIT_ROLE} || exit
oc delete ns ${TEST_NS} || exit
oc delete ns ${TEST_SA_NS} || exit

exit 0
