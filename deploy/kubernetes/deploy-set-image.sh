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
    echo  "    --tag [-t]         - [optional] PRPL image tag"
    echo  ""
    echo  " Examples"
    echo  "    ./deploy-set-image.sh --tag 40e9210d233448854e67d41605fd4a62cbb3ecda"
    echo  ""
    exit 1
}

ARG_USE_PRPL_IMAGE_TAG=
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

YYYYMMDD_HHMMSS=`date +'%Y%m%d_%H%M%S'`

PRPL_KUBERNETES_NAME=prpl

echo
kubectl get deployment ${PRPL_KUBERNETES_NAME}

kubectl set image deployment/${PRPL_KUBERNETES_NAME} prpl=${PRPL_DOCKER_REGISTRY}${PRPL_KUBERNETES_NAME}:${ARG_USE_PRPL_IMAGE_TAG}

echo
sleep 1
kubectl get deployment ${PRPL_KUBERNETES_NAME}
