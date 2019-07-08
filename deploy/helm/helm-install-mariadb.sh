#!/bin/bash
#
# Helm install mysql
set -o errexit
set -o nounset

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| helm-install-mysql - Helm install-mysql                              |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  "    --replicas [-r]          - [optional] Number of slave replicas"
    echo  ""
    echo  " Examples"
    echo  "    ./helm-install-mysql.sh --replicas 3"
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
HELM_RELEASE=prpl-db

PRPL_HELM_ARGS=
if [ "${ARG_REPLICAS}" != "" ] ; then
	PRPL_HELM_ARGS="${PRPL_HELM_ARGS} --set=slave.replicas=${ARG_REPLICAS}"
fi
helm install --name ${HELM_RELEASE} \
	--set rootUser.password=$(kubectl get secret --namespace default prpl-secrets -o jsonpath="{.data.PRPL_MYSQL_ROOT_PASSWORD}" | base64 --decode) \
	--set master.persistence.size=4Gi \
	--set slave.persistence.size=4Gi \
	${PRPL_HELM_ARGS} \
	stable/mariadb

# To connect a client to the db :

#  kubectl run prpl-db-mariadb-client --rm --tty -i --restart='Never' --image  docker.io/bitnami/mariadb:10.3.16-debian-9-r0 --namespace default --command -- mysql -h prpl-db-mariadb -u PRPL --database=PRPL -p

echo -e "\n----------"
echo "Finished helm install of mysql at `date` (started at ${START_DATE})"
