#!/bin/bash
#
# build and publish docker image
set -o errexit
set -o nounset

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| docker-build-image - Build image                                     |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  "    --make-jobs [-j]         - [optional] Number of make jobs, for parallelising build"
    echo  ""
    echo  " Examples"
    echo  "    ./docker-build-image.sh --make-jobs 4"
    echo  ""
    exit 1
}

ARG_MAKE_JOBS=2
ARG_RECOGNISED=FALSE
ARGS=$*
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "--help" -o  "$1" == "-h" ] ; then
		usage
	fi
	if [ "$1" == "--make-jobs" -o  "$1" == "-j" ] ; then
		shift 1
		ARG_MAKE_JOBS=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "ERROR: Invalid args : Unknown argument \"${1}\"."
		exit 1
	fi
	shift
done

START_DATE=`date`

source ../../docker-config.sh

# Common settings for build and publish docker images
PRPL_DOCKER_IMAGE_NAME=prpl-base
export PRPL_DOCKER_BUILD_DATE=`date`
export PRPL_DOCKER_IMAGE_TAG=`date +%Y%m%d%H%M%S`
echo ${PRPL_DOCKER_IMAGE_TAG} > DOCKER_IMAGE_TAG

echo "Building image ${PRPL_DOCKER_IMAGE_NAME} for tag ${PRPL_DOCKER_IMAGE_TAG}"
echo

echo -e "\n----------------------------------- Stop container -------------------------------------------\n"
#docker stop ${PRPL_DOCKER_IMAGE_NAME} || true
#docker rm ${PRPL_DOCKER_IMAGE_NAME} || true
#docker ps

echo -e "\n----------------------------------- Build image  ---------------------------------------------\n"
docker rmi ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME} || true
echo
docker build \
	--build-arg PRPL_MAKE_JOBS=${ARG_MAKE_JOBS} \
	--tag=${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}:${PRPL_DOCKER_IMAGE_TAG} \
	--file=./Dockerfile .
docker tag ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}:${PRPL_DOCKER_IMAGE_TAG} ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}:latest

echo
docker images

echo -e "\n--------------------------------------- Tag image --------------------------------------------\n"
# docker tag ${PRPL_DOCKER_IMAGE_NAME} ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}

if [ "${PRPL_DOCKER_REGISTRY}" != "" ] ; then
	echo -e "\n-------------------------------- Push image to Registry --------------------------------------\n"
	docker push ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}
fi

if [ "${PRPL_DOCKER_REGISTRY}" != "" ] ; then
	echo -e "\n-------------------------------- Pull image from Registry ------------------------------------\n"
	docker rmi ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}
	echo
	docker pull ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}:${PRPL_DOCKER_IMAGE_TAG}
fi

# echo -e "\n------------------------------------ Run container -------------------------------------------\n"
#docker run -d --name=${PRPL_DOCKER_IMAGE_NAME} -p 80:80/tcp -p 22/tcp ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}
#docker run -d --name=${PRPL_DOCKER_IMAGE_NAME} -P ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}

if [ "${PRPL_DOCKER_REGISTRY}" != "" ] ; then
	echo -e "\n--------------------------------  Registry contents ------------------------------------\n"
	curl -X GET https://${PRPL_DOCKER_REGISTRY}v2/_catalog 2>/dev/null | python -m json.tool
fi

echo -e "\n----------"
echo "Finished image ${PRPL_DOCKER_IMAGE_NAME} tag ${PRPL_DOCKER_IMAGE_TAG} at `date` (started at ${START_DATE})"
echo 
