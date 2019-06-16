#!/bin/bash
# Example usage of container to start Icecream container
#
set -o nounset
set -o errexit

ARG_LOGS_TAIL=FALSE
ARG_RECOGNISED=FALSE
ARGS=$*
# Check all args up front for early validation, since processing can take some time.
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "--help" -o  "$1" == "-h" ] ; then
		usage
	fi
	if [ "$1" == "--tail" -o "$1" == "-t" ] ; then
		ARG_LOGS_TAIL=TRUE
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "Invalid args : Unknown argument \"${1}\"."
		err 1
	fi
	shift
done

source ../../docker-config.sh

if [ ! -f ./DOCKER_IMAGE_TAG ] ; then
	echo "ERROR : cannot find file ./DOCKER_IMAGE_TAG"
	exit 1
fi

PRPL_DOCKER_IMAGE_NAME=prpl
PRPL_DOCKER_IMAGE_TAG=`cat ./DOCKER_IMAGE_TAG`

YYYYMMDD_HHMMSS=`date +'%Y%m%d_%H%M%S'`
PRPL_DOCKER_CONTAINER_NAME=prpl

echo "`date '+%Y%m%d %H:%M:%S'` : Deleting container ${PRPL_DOCKER_CONTAINER_NAME}"
docker stop ${PRPL_DOCKER_CONTAINER_NAME} || true
docker rm ${PRPL_DOCKER_CONTAINER_NAME} || true

echo "`date '+%Y%m%d %H:%M:%S'` : Starting container ${PRPL_DOCKER_CONTAINER_NAME}"
  # --net=host 
CONTAINER_ID=`docker run -d --name=${PRPL_DOCKER_CONTAINER_NAME} \
 --volume=/prpl \
 --memory-reservation=1GB \
 -p 8081:80/tcp \
 --env PRPL_SLEEP_SECS=1 \
 --env PRPL_SLEEP_TIMES=30 \
 ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}:${PRPL_DOCKER_IMAGE_TAG}`

if [ "${ARG_LOGS_TAIL}" == "TRUE" ] ; then
	docker logs -f ${CONTAINER_ID}
fi

