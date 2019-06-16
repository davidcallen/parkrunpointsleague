#!/bin/bash
#
# push docker image to GCP
set -o errexit
set -o nounset

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
		echo "Invalid args : Unknown argument \"${1}\"."
		err 1
	fi
	shift
done

START_DATE=`date`

source ../../docker-config.sh

# Common settings for build and publish docker images
PRPL_DOCKER_IMAGE_NAME=prpl-base
export PRPL_DOCKER_BUILD_DATE=`date`
export PRPL_DOCKER_IMAGE_TAG=`date +%Y%m%d%H%M%S`
if [ "${ARG_USE_PRPL_IMAGE_TAG}" == "" ] ; then
	IMAGE_TAG_FILE=./DOCKER_IMAGE_TAG
	if [ ! -f ${IMAGE_TAG_FILE} ] ; then
		echo "ERROR : cannot find file ${IMAGE_TAG_FILE}"
		exit 1
	fi
	PRPL_DOCKER_IMAGE_TAG=`cat ${IMAGE_TAG_FILE}`
else
	PRPL_DOCKER_IMAGE_TAG=${ARG_USE_PRPL_IMAGE_TAG}
	echo ${PRPL_DOCKER_IMAGE_TAG} > DOCKER_IMAGE_TAG
fi
set -x
echo "Push image ${PRPL_DOCKER_IMAGE_NAME} for tag ${PRPL_DOCKER_IMAGE_TAG} to GCP"
echo

docker tag ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}:${PRPL_DOCKER_IMAGE_TAG} ${PRPL_DOCKER_REGISTRY_GCP}${PRPL_DOCKER_IMAGE_NAME}:${PRPL_DOCKER_IMAGE_TAG}
docker push ${PRPL_DOCKER_REGISTRY_GCP}${PRPL_DOCKER_IMAGE_NAME}:${PRPL_DOCKER_IMAGE_TAG}

echo -e "\n----------"
echo "Finished push image ${PRPL_DOCKER_IMAGE_NAME} tag ${PRPL_DOCKER_IMAGE_TAG} to GCP at `date` (started at ${START_DATE})"
echo 
