#!/bin/bash
#
# Common settings for docker images and kubernetes

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| docker-config - Docker / k8s config                                  |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  "    --environment [-e]       - [optional] Force the environment to [local, minikube, gke]"
    echo  ""
    echo  " Examples"
    echo  "    ./docker-config.sh --environment local"
    echo  ""
    exit 1
}

ARG_ENVIRONMENT=
ARG_RECOGNISED=FALSE
ARGS=$*
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "--help" -o  "$1" == "-h" ] ; then
		usage
	fi
	if [ "$1" == "--environment" -o  "$1" == "-e" ] ; then
		shift 1
		ARG_ENVIRONMENT=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "ERROR: Invalid args : Unknown argument \"${1}\"."
		exit 1
	fi
	shift
done

PRPL_DOCKER_ENVIRONMENT=
if [ "${ARG_ENVIRONMENT}" != "" ] ; then
	PRPL_DOCKER_ENVIRONMENT=${ARG_ENVIRONMENT}
else
	KUBECTL_CONTEXT=`kubectl config current-context`
	if [ "${KUBECTL_CONTEXT}" == "" ] ; then
		PRPL_DOCKER_ENVIRONMENT=local
	elif [ "${KUBECTL_CONTEXT}" == "minikube" ] ; then
		PRPL_DOCKER_ENVIRONMENT=minikube
	elif [ "${KUBECTL_CONTEXT:0:3}" == "gke" ] ; then
		PRPL_DOCKER_ENVIRONMENT=gke
	else
		echo "ERROR : cannot detect environment (only minikube and GCP currently supported)."
	fi
fi
export PRPL_DOCKER_ENVIRONMENT

if [ "${PRPL_DOCKER_ENVIRONMENT}" == "local" ] ; then
	export PRPL_GCP_PROJECT_NAME=
	export PRPL_DOCKER_REGISTRY_HOSTNAME=
	export PRPL_DOCKER_REGISTRY=
elif [ "${PRPL_DOCKER_ENVIRONMENT}" == "minikube" ] ; then
	export PRPL_GCP_PROJECT_NAME=
	export PRPL_DOCKER_REGISTRY_HOSTNAME=
	export PRPL_DOCKER_REGISTRY=
elif [ "${PRPL_DOCKER_ENVIRONMENT}" == "gke" ] ; then
	export PRPL_GCP_PROJECT_NAME=`gcloud config get-value project`
	export PRPL_DOCKER_REGISTRY_HOSTNAME=eu.gcr.io
	export PRPL_DOCKER_REGISTRY=${PRPL_DOCKER_REGISTRY_HOSTNAME}/${PRPL_GCP_PROJECT_NAME}/
else
	echo "ERROR : cannot detect environment (only minikube and GCP currently supported)."
fi

echo "Using Docker environment ${PRPL_DOCKER_ENVIRONMENT} with Registry ${PRPL_DOCKER_REGISTRY}"
echo
