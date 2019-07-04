#!/bin/bash
#
# Helm install mariadb
set -o errexit
set -o nounset

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| helm-delete-mariadb - Helm delete Mariadb                            |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  "    --gcp [-g]               - [optional] Build image, tag and push to GCP registry"
    echo  ""
    echo  " Examples"
    echo  "    ./helm-delete-mariadb.sh --gcp"
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

source ../../docker/docker-config.sh

# Common settings for build and publish docker images
HELM_RELEASE=prpl-db

helm del --purge ${HELM_RELEASE} || true


echo -e "\n----------"
echo "Finished helm delete of mariadb at `date` (started at ${START_DATE})"
