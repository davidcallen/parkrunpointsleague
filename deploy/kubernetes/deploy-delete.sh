#!/bin/bash
# 
# Delete PRPL deployment
set -o nounset
set -o errexit

YYYYMMDD_HHMMSS=`date +'%Y%m%d_%H%M%S'`
# PRPL_DOCKER_CONTAINER_NAME=prpl
PRPL_KUBERNETES_NAME=prpl
PRPL_KUBERNETES_SERVICE_NAME=${PRPL_KUBERNETES_NAME}

echo "`date '+%Y%m%d %H:%M:%S'` : Deleting deployment ${PRPL_KUBERNETES_NAME}"
kubectl delete service ${PRPL_KUBERNETES_SERVICE_NAME} || true
kubectl delete deployment ${PRPL_KUBERNETES_NAME} || true

