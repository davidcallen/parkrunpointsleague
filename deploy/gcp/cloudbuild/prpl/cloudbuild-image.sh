#!/bin/bash
#
# build and publish docker image using GCloud Build
set -o errexit
set -o nounset

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

GCLOUD_BUILD_SUBSTITUTIONS=--substitutions=_PRPL_BASE_DOCKER_IMAGE_TAG=${PRPL_BASE_DOCKER_IMAGE_TAG}
GCLOUD_BUILD_SUBSTITUTIONS=${GCLOUD_BUILD_SUBSTITUTIONS},_PRPL_DOCKER_IMAGE_TAG=${PRPL_DOCKER_IMAGE_TAG}
if [ "${ARG_MAKE_JOBS}" != "" ] ; then
	GCLOUD_BUILD_SUBSTITUTIONS=${GCLOUD_BUILD_SUBSTITUTIONS},_PRPL_MAKE_JOBS=${ARG_MAKE_JOBS}
fi
if [ "${ARG_USE_LOCAL_SOURCES}" != "" ] ; then
	GCLOUD_BUILD_SUBSTITUTIONS=${GCLOUD_BUILD_SUBSTITUTIONS},_PRPL_USE_LOCAL_SOURCES=${ARG_USE_LOCAL_SOURCES}
fi

cat cloudbuild.yaml | sed "s/:\${COMMIT_SHA}/:\${_PRPL_DOCKER_IMAGE_TAG}/g" > cloudbuild.yaml.tmp

gcloud builds submit ${GCLOUD_BUILD_SUBSTITUTIONS} --config cloudbuild.yaml.tmp ../../../../
rm -f cloudbuild.yaml.tmp

echo -e "\n----------"
echo "Finished google cloud build of image '${PRPL_DOCKER_IMAGE_NAME}' with tag ${PRPL_DOCKER_IMAGE_TAG} at `date` (started at ${START_DATE})"
