#!/bin/bash
# 
# Delete PRPL deployment
set -o nounset
set -o errexit

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| deploy-delete.sh - Delete deployment in k8s                           |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  ""
    echo  " Examples"
    echo  "    ./deploy-delete.sh"
    echo  ""
    exit 1
}

ARG_RECOGNISED=FALSE
ARGS=$*
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "--help" -o  "$1" == "-h" ] ; then
		usage
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "ERROR: Invalid args : Unknown argument \"${1}\"."
		exit 1
	fi
	shift
done

YYYYMMDD_HHMMSS=`date +'%Y%m%d_%H%M%S'`
# PRPL_DOCKER_CONTAINER_NAME=prpl
PRPL_KUBERNETES_NAME=prpl
PRPL_KUBERNETES_SERVICE_NAME=${PRPL_KUBERNETES_NAME}

echo "`date '+%Y%m%d %H:%M:%S'` : Deleting deployment ${PRPL_KUBERNETES_NAME}"
kubectl delete service ${PRPL_KUBERNETES_SERVICE_NAME} || true
kubectl delete deployment ${PRPL_KUBERNETES_NAME} || true

