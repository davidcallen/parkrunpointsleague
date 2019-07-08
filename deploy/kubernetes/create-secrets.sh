#!/bin/bash
# 
# Create deployment
set -o nounset
set -o errexit

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| create-secrets.sh - Create secrets in k8s                            |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  ""
    echo  " Examples"
    echo  "    ./create-secrets.sh"
    echo  ""
    exit 1
}

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


# PRPL_DOCKER_CONTAINER_NAME=prpl
PRPL_KUBERNETES_SECRETS_NAME=prpl-secrets

kubectl delete secret ${PRPL_KUBERNETES_SECRETS_NAME} || true

read -p "Enter Database ROOT user password 'PRPL_MYSQL_ROOT_PASSWORD' : " PRPL_MYSQL_ROOT_PASSWORD

read -p "Enter Database PRPL app user password 'PRPL_DATABASE_PWD' : " PRPL_DATABASE_PWD

read -p "Enter Jenkins admin user password 'PRPL_JENKINS_ADMIN_PASSWORD' : " PRPL_JENKINS_ADMIN_PASSWORD

# echo PRPL_MYSQL_ROOT_PASSWORD=${PRPL_MYSQL_ROOT_PASSWORD}  PRPL_DATABASE_PWD=${PRPL_DATABASE_PWD} 

kubectl create secret generic ${PRPL_KUBERNETES_SECRETS_NAME} --type=string \
	--from-literal=PRPL_DATABASE_PWD="${PRPL_DATABASE_PWD}" \
	--from-literal=PRPL_MYSQL_ROOT_PASSWORD="${PRPL_MYSQL_ROOT_PASSWORD}" \
	--from-literal=PRPL_JENKINS_ADMIN_PASSWORD="${PRPL_JENKINS_ADMIN_PASSWORD}"

# Check secrets with :
kubectl get secrets
kubectl describe secret ${PRPL_KUBERNETES_SECRETS_NAME}


