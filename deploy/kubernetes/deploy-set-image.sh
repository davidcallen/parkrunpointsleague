#!/bin/bash
# Example usage of container to start Icecream container
#
set -o nounset
set -o errexit

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| deploy-set-image.sh - Change deploy image on k8s                     |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  "    --gcp [-g]         - [optional] Deploy to GCP"
    echo  "    --tag [-t]         - [optional] PRPL image tag"
    echo  ""
    echo  " Examples"
    echo  "    ./deploy-set-image.sh --gcp --tag 40e9210d233448854e67d41605fd4a62cbb3ecda"
    echo  ""
    exit 1
}

ARG_USE_PRPL_IMAGE_TAG=
ARG_DEPLOY_TO_GCP=FALSE
ARG_RECOGNISED=FALSE
ARGS=$*
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "--help" -o  "$1" == "-h" ] ; then
		usage
	fi
	if [ "$1" == "--tag" -o "$1" == "-t" ] ; then
		shift 1
		ARG_USE_PRPL_IMAGE_TAG=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "$1" == "--gcp" -o "$1" == "-g" ] ; then
		ARG_DEPLOY_TO_GCP=TRUE
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "ERROR: Invalid args : Unknown argument \"${1}\"."
		exit 1
	fi
	shift
done

if [ "${ARG_USE_PRPL_IMAGE_TAG}" == "" ] ; then
	echo "ERROR : arg --tag is mandatory"
	exit 1
fi

source ../docker/docker-config.sh
YYYYMMDD_HHMMSS=`date +'%Y%m%d_%H%M%S'`

PRPL_KUBERNETES_NAME=prpl

echo
kubectl get deployment ${PRPL_KUBERNETES_NAME}

if [ "${ARG_DEPLOY_TO_GCP}" == "TRUE" ] ; then
	kubectl set image deployment/${PRPL_KUBERNETES_NAME} prpl=${PRPL_DOCKER_REGISTRY_GCP}${PRPL_KUBERNETES_NAME}:${ARG_USE_PRPL_IMAGE_TAG}
else
	kubectl set image deployment/${PRPL_KUBERNETES_NAME} prpl=${PRPL_KUBERNETES_NAME}:${ARG_USE_PRPL_IMAGE_TAG}
fi

echo
sleep 1
kubectl get deployment ${PRPL_KUBERNETES_NAME}
