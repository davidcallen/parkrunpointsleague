#!/bin/bash
#
# build and publish docker image using GCloud Build
set -o errexit
set -o nounset

ARG_MAKE_JOBS=
ARG_RECOGNISED=FALSE
ARGS=$*
# Check all args up front for early validation, since processing can take some time.
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "--help" -o  "$1" == "-h" ] ; then
		usage
	fi
	if [ "$1" == "--make-jobs" -o  "$1" == "-j" ] ; then
		shift 1
		ARG_MAKE_JOBS=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "Invalid args : Unknown argument \"${1}\"."
		err 1
	fi
	shift
done

START_DATE=`date`
echo "\nStarted google cloud build at ${START_DATE}\n"

PRPL_DOCKER_IMAGE_NAME=prpl-base
PRPL_DOCKER_BUILD_DATE=`date`
PRPL_DOCKER_IMAGE_TAG=`date +%Y%m%d%H%M%S`

echo ${PRPL_DOCKER_IMAGE_TAG} > ../../../docker/image/prpl-base/DOCKER_IMAGE_TAG

GCLOUD_BUILD_SUBSTITUTIONS=--substitutions=_PRPL_DOCKER_IMAGE_TAG=${PRPL_DOCKER_IMAGE_TAG}
if [ "${ARG_MAKE_JOBS}" != "" ] ; then
	GCLOUD_BUILD_SUBSTITUTIONS=${GCLOUD_BUILD_SUBSTITUTIONS},_PRPL_MAKE_JOBS=${ARG_MAKE_JOBS}
fi

gcloud builds submit ${GCLOUD_BUILD_SUBSTITUTIONS} --config cloudbuild.yaml ../../../../

echo -e "\n----------"
echo "Finished google cloud build of image '${PRPL_DOCKER_IMAGE_NAME}' with tag ${PRPL_DOCKER_IMAGE_TAG} at `date` (started at ${START_DATE})"