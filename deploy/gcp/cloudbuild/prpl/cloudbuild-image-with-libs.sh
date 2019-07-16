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
    echo  "    --base-tag [-t]          - [optional] The image tag for prpl-base"
    echo  "    --make-jobs [-j]         - [optional] Number of make jobs, for parallelising build"
    echo  "    --use-local-source [-l]  - [optional] Use local source files (useful for testing)"    
    echo  ""
    echo  " Examples"
    echo  "    ./cloudbuild-image.sh --base-tag 20190617184216 --make-jobs 2 --use-local-sources"
    echo  ""
    exit 1
}

ARG_USE_PRPL_BASE_IMAGE_TAG=
ARG_MAKE_JOBS=
ARG_USE_LOCAL_SOURCES=
ARG_RECOGNISED=FALSE
ARGS=$*
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "--help" -o  "$1" == "-h" ] ; then
		usage
	fi
	if [ "$1" == "--base-tag" -o "$1" == "-t" ] ; then
		shift 1
		ARG_USE_PRPL_BASE_IMAGE_TAG=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "$1" == "--make-jobs" -o  "$1" == "-j" ] ; then
		shift 1
		ARG_MAKE_JOBS=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "$1" == "--use-local-sources" -o "$1" == "-l" ] ; then
		ARG_USE_LOCAL_SOURCES=TRUE
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "ERROR: Invalid args : Unknown argument \"${1}\"."
		exit 1
	fi
	shift
done

START_DATE=`date`
echo -e "\nStarted google cloud build at ${START_DATE}\n"

PRPL_DOCKER_IMAGE_NAME=prpl
PRPL_DOCKER_BUILD_DATE=`date`
PRPL_DOCKER_IMAGE_TAG=`date +%Y%m%d%H%M%S`

echo ${PRPL_DOCKER_IMAGE_TAG} > ../../../docker/image/prpl/DOCKER_IMAGE_TAG
export PRPL_BASE_DOCKER_IMAGE_TAG=`cat ../../../docker/image/prpl-base/DOCKER_IMAGE_TAG`
if [ "${ARG_USE_PRPL_BASE_IMAGE_TAG}" != "" ] ; then
	PRPL_BASE_DOCKER_IMAGE_TAG=${ARG_USE_PRPL_BASE_IMAGE_TAG}
fi

GCLOUD_BUILD_SUBSTITUTIONS=--substitutions=_PRPL_GCP_PROJECT_NAME=${PRPL_GCP_PROJECT_NAME}
GCLOUD_BUILD_SUBSTITUTIONS=${GCLOUD_BUILD_SUBSTITUTIONS},_PRPL_DOCKER_REGISTRY=${PRPL_DOCKER_REGISTRY}
GCLOUD_BUILD_SUBSTITUTIONS=${GCLOUD_BUILD_SUBSTITUTIONS},_PRPL_BASE_DOCKER_IMAGE_TAG=${PRPL_BASE_DOCKER_IMAGE_TAG}
GCLOUD_BUILD_SUBSTITUTIONS=${GCLOUD_BUILD_SUBSTITUTIONS},_PRPL_DOCKER_IMAGE_TAG=${PRPL_DOCKER_IMAGE_TAG}
if [ "${ARG_MAKE_JOBS}" != "" ] ; then
	GCLOUD_BUILD_SUBSTITUTIONS=${GCLOUD_BUILD_SUBSTITUTIONS},_PRPL_MAKE_JOBS=${ARG_MAKE_JOBS}
fi

cat cloudbuild-with-libs.yaml | sed "s/:\${COMMIT_SHA}/:\${_PRPL_DOCKER_IMAGE_TAG}/g" > cloudbuild-with-libs.yaml.tmp

gcloud builds submit ${GCLOUD_BUILD_SUBSTITUTIONS} --config cloudbuild-with-libs.yaml.tmp ../../../docker/image/prpl
rm -f cloudbuild-with-libs.yaml.tmp

echo -e "\n----------"
echo "Finished google cloud build of image '${PRPL_DOCKER_IMAGE_NAME}' with tag ${PRPL_DOCKER_IMAGE_TAG} at `date` (started at ${START_DATE})"
