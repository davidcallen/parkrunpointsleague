#!/bin/bash
#
# Access the Dashboard using the kubectl proxy
#
# ParkRun Points League  (licensed under GPL v3)
#
set -o errexit
set -o nounset

# Get the secret token in order to connect to the dashboard
FULL_CONTROL_ENABLED=TRUE
NAMESPACE=kubernetes-dashboard
SECRET_NAME=kubernetes-dashboard-token
if [ "${FULL_CONTROL_ENABLED}" == "TRUE" ] ; then
  # Full control of the cluster
  NAMESPACE=kube-system
  SECRET_NAME=eks-admin
fi
EKS_ADMIN_TOKEN_SECRET_NAME=$(kubectl${PRPL_KUBECTL_VERSION} -n ${NAMESPACE} get secret | grep ${SECRET_NAME} | awk '{print $1}')
kubectl${PRPL_KUBECTL_VERSION} -n ${NAMESPACE} describe secret ${EKS_ADMIN_TOKEN_SECRET_NAME}

# Use the token from above output when logging in to Dashboard next ...
#
echo -e "\nDashboard should now be available here http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:https/proxy/#/login \n"

# Invoke the Proxy to give access to the Dashboard
kubectl${PRPL_KUBECTL_VERSION} proxy

