#!/bin/bash
#
# Helm upgrade jenkins to change number of replicas
set -o errexit
set -o nounset

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| helm-upgrade-jenkins - Helm upgrade jenkins                          |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  "    --replicas [-r]          - [optional] Number of slave replicas"
    echo  ""
    echo  " Examples"
    echo  "    ./helm-upgrade-jenkins.sh --replicas"
    echo  ""
    exit 1
}

ARG_USE_PRPL_IMAGE_TAG=
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
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "ERROR: Invalid args : Unknown argument \"${1}\"."
		exit 1
	fi
	shift
done

START_DATE=`date`

# Common settings for build and publish docker images
HELM_RELEASE=prpl-jenkins

PRPL_HELM_ARGS=
if [ "${ARG_REPLICAS}" != "" ] ; then
	PRPL_HELM_ARGS="${PRPL_HELM_ARGS} --set=slave.replicas=${ARG_REPLICAS}"
fi
helm upgrade ${HELM_RELEASE} \
	${PRPL_HELM_ARGS} \
	stable/jenkins

echo -e "\n----------"
echo "Finished helm upgrade of jenkins at `date` (started at ${START_DATE})"
