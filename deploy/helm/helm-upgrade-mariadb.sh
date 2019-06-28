#!/bin/bash
#
# Helm upgrade mariadb to change number of replicas
set -o errexit
set -o nounset

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| helm-upgrade-mariadb - Helm upgrade mariadb                          |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  "    --replicas [-r]          - [optional] Number of slave replicas"
    echo  ""
    echo  " Examples"
    echo  "    ./helm-upgrade-mariadb.sh --replicas"
    echo  ""
    exit 1
}

ARG_USE_PRPL_IMAGE_TAG=
ARG_DEPLOY_TO_GCP=FALSE
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
HELM_RELEASE=prpl-db

PRPL_HELM_ARGS=
if [ "${ARG_REPLICAS}" != "" ] ; then
	PRPL_HELM_ARGS="${PRPL_HELM_ARGS} --set=slave.replicas=${ARG_REPLICAS}"
fi
helm upgrade ${HELM_RELEASE} \
	${PRPL_HELM_ARGS} \
	stable/mariadb

echo -e "\n----------"
echo "Finished helm upgrade of mariadb at `date` (started at ${START_DATE})"
