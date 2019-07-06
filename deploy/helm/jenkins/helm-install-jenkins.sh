#!/bin/bash
#
# Helm install jenkins
set -o errexit
set -o nounset

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| helm-install-jenkins - Helm install-jenkins                              |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  "    --replicas [-r]          - [optional] Number of slave replicas"
    echo  "    --gcp [-g]               - [optional] Build image, tag and push to GCP registry"
    echo  ""
    echo  " Examples"
    echo  "    ./helm-install-jenkins.sh --gcp"
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

source ../../docker/docker-config.sh

# Common settings for build and publish docker images
HELM_RELEASE=prpl-jenkins

#PRPL_HELM_ARGS=
#if [ "${ARG_DEPLOY_TO_GCP}" == "TRUE" ] ; then
#	echo "gcp"
#fi
PRPL_HELM_ARGS=
if [ "${ARG_REPLICAS}" != "" ] ; then
	PRPL_HELM_ARGS="${PRPL_HELM_ARGS} --set=slave.replicas=${ARG_REPLICAS}"
fi
set -x
if [ "`kubectl config current-context`" == "minikube" ] ; then
	kubectl apply -f jenkins-volume-minikube.yaml
	PRPL_HELM_ARGS="${PRPL_HELM_ARGS} --set=persistence.existingClaim=prpl-jenkins-pvc"
fi

helm install --name ${HELM_RELEASE} \
	-f values.yaml \
	--set=master.adminPassword=`echo $(kubectl get secret --namespace default prpl-secrets -o jsonpath="{.data.PRPL_JENKINS_ADMIN_PASSWORD}" | base64 --decode)` \
	${PRPL_HELM_ARGS} \
	stable/jenkins

echo -e "\n----------"
echo "Finished helm install of jenkins at `date` (started at ${START_DATE})"
