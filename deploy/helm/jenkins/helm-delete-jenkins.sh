#!/bin/bash
#
# Helm install jenkins
set -o errexit
set -o nounset

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| helm-delete-jenkins - Helm delete jenkins                            |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  "    --delete-pv [-d]          - [optional] Delete the PersistentVolume and Claim"
    echo  ""
    echo  " Examples"
    echo  "    ./helm-delete-jenkins.sh"
    echo  ""
    exit 1
}

ARG_USE_PRPL_IMAGE_TAG=
ARG_DELETE_PV=FALSE
ARG_RECOGNISED=FALSE
ARGS=$*
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "--help" -o  "$1" == "-h" ] ; then
		usage
	fi
	if [ "$1" == "--delete-pv" -o "$1" == "-d" ] ; then
		ARG_DELETE_PV=TRUE
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

helm del --purge ${HELM_RELEASE} || true

if [ "${ARG_DELETE_PV}" == "TRUE" ] ; then
	echo "Deleting pv and pvc..."
	kubectl delete pvc ${HELM_RELEASE}-pvc || true
	kubectl delete pv ${HELM_RELEASE}-pv || true
fi

echo -e "\n----------"
echo "Finished helm delete of jenkins at `date` (started at ${START_DATE})"
