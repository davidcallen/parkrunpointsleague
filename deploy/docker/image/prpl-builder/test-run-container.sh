#!/bin/bash
# Example usage of container to start Icecream container
#
set -o nounset
set -o errexit

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| test-run-container.sh    - Test run of container image in docker     |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  "    --tail [-t]               - [optional] Tail log file"
    echo  ""
    echo  " Examples"
    echo  "    ./test-run-container.sh --tail"
    echo  ""
    exit 1
}

ARG_LOGS_TAIL=FALSE
ARG_RECOGNISED=FALSE
ARGS=$*
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
		echo "ERROR: Invalid args : Unknown argument \"${1}\"."
		exit 1
	fi
	shift
done

if [ ! -f ./DOCKER_IMAGE_TAG ] ; then
	echo "ERROR : cannot find file ./DOCKER_IMAGE_TAG"
	exit 1
fi

PRPL_DOCKER_IMAGE_NAME=prpl-builder
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
