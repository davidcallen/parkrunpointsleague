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
    echo  "    --mariadb [-m]           - [optional] Use mariadb for database"
    echo  ""
    echo  " Examples"
    echo  "    ./helm-install.sh --tag 20190704121253 --mariadb"
    echo  ""
    exit 1
}

ARG_USE_PRPL_IMAGE_TAG=
ARG_USE_MARIADB=FALSE
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
	if [ "$1" == "--mariadb" -o "$1" == "-m" ] ; then
		ARG_USE_MARIADB=TRUE
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "ERROR: Invalid args : Unknown argument \"${1}\"."
		exit 1
	fi
	shift
done

START_DATE=`date`

# Common settings for build and publish docker images
PRPL_DOCKER_IMAGE_NAME=prpl
PRPL_DOCKER_IMAGE_TAG=`cat ../docker/image/prpl/DOCKER_IMAGE_TAG`
PRPL_DOCKER_IMAGE_TAG=latest
if [ "${ARG_USE_PRPL_IMAGE_TAG}" != "" ] ; then
	PRPL_DOCKER_IMAGE_TAG=${ARG_USE_PRPL_IMAGE_TAG}
fi
export PRPL_DOCKER_IMAGE_TAG

helm del --purge prpl || true

PRPL_HELM_ARGS=
if [ "${PRPL_DOCKER_ENVIRONMENT}" != "" ] ; then
	echo "Deploying to GCP GKE"
	PRPL_HELM_ARGS="--values=config-${PRPL_DOCKER_ENVIRONMENT}.yaml"
fi
if [ "${ARG_USE_MARIADB}" == "TRUE" ] ; then
	echo "Using MariaDB"
	PRPL_HELM_ARGS="--values=config-mariadb.yaml"
fi
helm install --name prpl ../helm --values=values.yaml ${PRPL_HELM_ARGS} --set-string=image.tag="${PRPL_DOCKER_IMAGE_TAG}"

echo -e "\n----------"
echo "Finished helm install of ${PRPL_DOCKER_IMAGE_NAME} tag ${PRPL_DOCKER_IMAGE_TAG} at `date` (started at ${START_DATE})"
