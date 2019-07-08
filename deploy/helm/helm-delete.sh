#!/bin/bash
#
# Helm delete prpl
set -o errexit
set -o nounset

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| helm-delete - Helm delete prpl                                       |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  ""
    echo  " Examples"
    echo  "    ./helm-delete.sh"
    echo  ""
    exit 1
}

ARG_USE_PRPL_IMAGE_TAG=
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

# Common settings for build and publish docker images
HELM_RELEASE=prpl

helm del --purge ${HELM_RELEASE} || true


echo -e "\n----------"
echo "Finished helm delete of prpl at `date` (started at ${START_DATE})"
