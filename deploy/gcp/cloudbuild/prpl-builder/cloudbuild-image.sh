#!/bin/bash
#
# build and publish docker image using GCloud Build
set -o errexit
set -o nounset

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| cloudbuild-image.sh - Create docker image using GCP Cloudbuild       |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  ""
    echo  " Examples"
    echo  "    ./cloudbuild-image.sh"
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

START_DATE=`date`
echo -e "\nStarted google cloud build at ${START_DATE}\n"

PRPL_DOCKER_IMAGE_NAME=prpl-builder
PRPL_DOCKER_BUILD_DATE=`date`
PRPL_DOCKER_IMAGE_TAG=`date +%Y%m%d%H%M%S`

echo ${PRPL_DOCKER_IMAGE_TAG} > ../../../docker/image/prpl-builder/DOCKER_IMAGE_TAG

GCLOUD_BUILD_SUBSTITUTIONS=--substitutions=_PRPL_GCP_PROJECT_NAME=${PRPL_GCP_PROJECT_NAME}
GCLOUD_BUILD_SUBSTITUTIONS=${GCLOUD_BUILD_SUBSTITUTIONS},_PRPL_DOCKER_REGISTRY=${PRPL_DOCKER_REGISTRY}
GCLOUD_BUILD_SUBSTITUTIONS=${GCLOUD_BUILD_SUBSTITUTIONS},_PRPL_DOCKER_IMAGE_TAG=${PRPL_DOCKER_IMAGE_TAG}

cat cloudbuild.yaml | sed "s/:\${COMMIT_SHA}/:\${_PRPL_DOCKER_IMAGE_TAG}/g" > cloudbuild.yaml.tmp

gcloud builds submit ${GCLOUD_BUILD_SUBSTITUTIONS} --config cloudbuild.yaml.tmp ../../../docker/image/prpl-builder
rm -f cloudbuild.yaml.tmp

echo -e "\n----------"
echo "Finished google cloud build of image '${PRPL_DOCKER_IMAGE_NAME}' with tag ${PRPL_DOCKER_IMAGE_TAG} at `date` (started at ${START_DATE})"
