#!/bin/bash
# Example usage of container to start Icecream container
#
set -o nounset
set -o errexit

ARG_USE_PRPL_IMAGE_TAG=
ARG_REPLICAS=
ARG_RECOGNISED=FALSE
ARGS=$*
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "--help" -o  "$1" == "-h" ] ; then
		usage
	fi
	if [ "$1" == "--replicas" -o "$1" == "-r" ] ; then
		shift 1
		ARG_REPLICAS=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "$1" == "--tag" -o "$1" == "-t" ] ; then
		shift 1
		ARG_USE_PRPL_IMAGE_TAG=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "Invalid args : Unknown argument \"${1}\"."
		err 1
	fi
	shift
done

if [ "${ARG_REPLICAS}" == "" ] ; then
	echo "ERROR : arg --replicas is mandatory"
	exit 1
fi

source ../docker/docker-config.sh
YYYYMMDD_HHMMSS=`date +'%Y%m%d_%H%M%S'`

PRPL_KUBERNETES_NAME=prpl

echo
kubectl get deployment ${PRPL_KUBERNETES_NAME}

kubectl scale deployment/prpl --replicas=${ARG_REPLICAS}
echo
sleep 1
kubectl get deployment ${PRPL_KUBERNETES_NAME}

