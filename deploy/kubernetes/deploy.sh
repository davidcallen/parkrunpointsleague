#!/bin/bash
# Example usage of container to start Icecream container
#
set -o nounset
set -o errexit

ARG_USE_PRPL_IMAGE_TAG=
ARG_RECOGNISED=FALSE
ARGS=$*
# Check all args up front for early validation, since processing can take some time.
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
		echo "Invalid args : Unknown argument \"${1}\"."
		err 1
	fi
	shift
done

source ../docker/docker-config.sh

if [ "${ARG_USE_PRPL_IMAGE_TAG}" == "" ] ; then
	IMAGE_TAG_FILE=../docker/image/prpl/DOCKER_IMAGE_TAG
	if [ ! -f ${IMAGE_TAG_FILE} ] ; then
		echo "ERROR : cannot find file ${IMAGE_TAG_FILE}"
		exit 1
	fi
	PRPL_DOCKER_IMAGE_TAG=`cat ${IMAGE_TAG_FILE}`
else
	PRPL_DOCKER_IMAGE_TAG=${ARG_USE_PRPL_IMAGE_TAG}
fi
PRPL_DOCKER_IMAGE_REPO=
PRPL_DOCKER_IMAGE_NAME=prpl

YYYYMMDD_HHMMSS=`date +'%Y%m%d_%H%M%S'`
# PRPL_DOCKER_CONTAINER_NAME=prpl
PRPL_KUBERNETES_NAME=prpl

echo "`date '+%Y%m%d %H:%M:%S'` : Stopping deployment ${PRPL_KUBERNETES_NAME}"
kubectl delete deployment ${PRPL_KUBERNETES_NAME} || true

echo "`date '+%Y%m%d %H:%M:%S'` : Starting deployment ${PRPL_KUBERNETES_NAME}"
export PRPL_DOCKER_IMAGE_TAG
export PRPL_DOCKER_IMAGE_REPO
#cat deployment.yaml | sed "s/{{PRPL_DOCKER_IMAGE_TAG}}/${PRPL_DOCKER_IMAGE_TAG}/g" | kubectl create -f -
cat deployment.yaml | envsubst | kubectl create -f -

# | kubectl create -f -

# kubectl run ${PRPL_KUBERNETES_NAME} --image=${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}:${PRPL_DOCKER_IMAGE_TAG} --port=8080 --image-pull-policy=Never

echo
kubectl get deployment ${PRPL_KUBERNETES_NAME}
