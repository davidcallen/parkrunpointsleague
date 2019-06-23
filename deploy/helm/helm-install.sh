#!/bin/bash
#
# Helm install
set -o errexit
set -o nounset

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| helm-install - Helm install                                          |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  "    --tag [-t]               - [optional] The image tag"
    echo  "    --gcp [-g]               - [optional] Build image, tag and push to GCP registry"
    echo  ""
    echo  " Examples"
    echo  "    ./helm-install.sh --gcp"
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

START_DATE=`date`

source ../docker/docker-config.sh

# Common settings for build and publish docker images
PRPL_DOCKER_IMAGE_NAME=prpl
PRPL_DOCKER_IMAGE_TAG=`cat ../docker/image/prpl/DOCKER_IMAGE_TAG`
PRPL_DOCKER_IMAGE_TAG=latest
if [ "${ARG_USE_PRPL_IMAGE_TAG}" != "" ] ; then
	PRPL_DOCKER_IMAGE_TAG=${ARG_USE_PRPL_IMAGE_TAG}
fi
export PRPL_DOCKER_IMAGE_TAG
if [ "${ARG_DEPLOY_TO_GCP}" == "TRUE" ] ; then
    PRPL_DOCKER_REGISTRY=${PRPL_DOCKER_REGISTRY_GCP}
fi

helm del --purge prpl || true

PRPL_HELM_ARGS=
if [ "${ARG_DEPLOY_TO_GCP}" == "TRUE" ] ; then
	echo "gcp"
	PRPL_HELM_ARGS="--values=config-gcp.yaml"
fi
helm install --name prpl ../helm --values=values.yaml ${PRPL_HELM_ARGS} --set-string=image.tag="${PRPL_DOCKER_IMAGE_TAG}"

echo -e "\n----------"
echo "Finished helm install of ${PRPL_DOCKER_IMAGE_NAME} tag ${PRPL_DOCKER_IMAGE_TAG} at `date` (started at ${START_DATE})"
