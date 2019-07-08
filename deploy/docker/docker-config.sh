#!/bin/bash
#
# Common settings for docker images and kubernetes
set -o errexit
set -o nounset

PRPL_DOCKER_ENVIRONMENT=
KUBECTL_CONTEXT=`kubectl config current-context`
if [ "${KUBECTL_CONTEXT}" == "minikube" ] ; then
	export PRPL_DOCKER_ENVIRONMENT=minikube
	export PRPL_DOCKER_REGISTRY=
elif [ "${KUBECTL_CONTEXT:0:3}" == "gke" ] ; then
	export PRPL_DOCKER_ENVIRONMENT=gke
	export PRPL_GCP_PROJECT_NAME=`gcloud config get-value project`
	export PRPL_DOCKER_REGISTRY=eu.gcr.io/${PRPL_GCP_PROJECT_NAME}/
else
	echo "ERROR : cannot detect environment (only minikube and GCP currently supported)."
fi

echo "Using Docker environment ${PRPL_DOCKER_ENVIRONMENT} with Registry ${PRPL_DOCKER_REGISTRY}"
echo
