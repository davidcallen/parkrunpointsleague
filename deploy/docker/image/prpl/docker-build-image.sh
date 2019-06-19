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
    echo  "    --use-local-source [-l]  - [optional] Use local source files (useful for testing)"
    echo  "    --gcp [-g]               - [optional] Build image, tag and push to GCP registry"
    echo  ""
    echo  " Examples"
    echo  "    ./docker-build-image.sh --make-jobs 4 --gcp"
    echo  ""
    exit 1
}

ARG_MAKE_JOBS=2
ARG_USE_LOCAL_SOURCES=FALSE
ARG_DEPLOY_TO_GCP=FALSE
ARG_RECOGNISED=FALSE
ARGS=$*
# Check all args up front for early validation, since processing can take some time.
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
	if [ "$1" == "--use-local-sources" -o "$1" == "-l" ] ; then
		ARG_USE_LOCAL_SOURCES=TRUE
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

source ../../docker-config.sh

# Common settings for build and publish docker images
PRPL_DOCKER_IMAGE_NAME=prpl
export PRPL_DOCKER_BUILD_DATE=`date`
export PRPL_DOCKER_IMAGE_TAG=`date +%Y%m%d%H%M%S`
echo ${PRPL_DOCKER_IMAGE_TAG} > DOCKER_IMAGE_TAG
export PRPL_BASE_DOCKER_IMAGE_TAG=`cat ../prpl-base/DOCKER_IMAGE_TAG`
if [ "${ARG_DEPLOY_TO_GCP}" == "TRUE" ] ; then
    PRPL_DOCKER_REGISTRY=${PRPL_DOCKER_REGISTRY_GCP}
fi

echo "Building image ${PRPL_DOCKER_IMAGE_NAME} for tag ${PRPL_DOCKER_IMAGE_TAG}"
echo

# If wanting to test docker build using our local sources
if [ "${ARG_USE_LOCAL_SOURCES}" == "TRUE" ] ; then
	if [ -d ./prpl.srcs.tar.gz ] ; then
		rm -rf prpl.srcs.tar.gz
	fi
	PRPL_TEMP_DIR=`mktemp -d`
	tar --exclude='../../../../../prpl/src/poco' \
		--exclude='../../../../../prpl/data/*' \
		--exclude='../../../../../prpl/src/external/*' \
		--exclude='../../../../../prpl/bin/*' \
		--exclude='../../../../../prpl/.git' \
		--exclude='../../../../../prpl/src/exe/prpld/CMakeFiles' \
		-cvf ${PRPL_TEMP_DIR}/prpl.srcs.tar.gz ../../../../../prpl
	cp -r ${PRPL_TEMP_DIR}/prpl.srcs.tar.gz .
fi

echo -e "\n----------------------------------- Stop container -------------------------------------------\n"
#docker stop ${PRPL_DOCKER_IMAGE_NAME} || true
#docker rm ${PRPL_DOCKER_IMAGE_NAME} || true
#docker ps

echo -e "\n----------------------------------- Build image  ---------------------------------------------\n"
docker rmi ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME} || true
echo
[ -f Dockerfile.tmp ] && rm -f Dockerfile.tmp
set -x
cp Dockerfile Dockerfile.tmp
sed -i "s/<<PRPL_BASE_DOCKER_IMAGE_TAG>>/${PRPL_BASE_DOCKER_IMAGE_TAG}/g" Dockerfile.tmp
if [ "${ARG_USE_LOCAL_SOURCES}" == "TRUE" ] ; then
	sed -i "s/<<COMMENT_OUT_IF_USE_LOCAL_SOURCES>>/\#/g" Dockerfile.tmp
	sed -i "s/<<COMMENT_OUT_IF_NOT_USE_LOCAL_SOURCES>>//g" Dockerfile.tmp
else
	sed -i "s/<<COMMENT_OUT_IF_USE_LOCAL_SOURCES>>//g" Dockerfile.tmp
	sed -i "s/<<COMMENT_OUT_IF_NOT_USE_LOCAL_SOURCES>>/\#/g" Dockerfile.tmp
fi
sed -i "s/<<PRPL_DOCKER_REGISTRY>>/${PRPL_DOCKER_REGISTRY}/g" Dockerfile.tmp
docker build --build-arg PRPL_BASE_DOCKER_IMAGE_TAG=${PRPL_BASE_DOCKER_IMAGE_TAG} \
	--build-arg PRPL_USE_LOCAL_SOURCES=${ARG_USE_LOCAL_SOURCES} \
	--build-arg PRPL_MAKE_JOBS=${ARG_MAKE_JOBS} \
	--tag=${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}:${PRPL_DOCKER_IMAGE_TAG} \
	--file=./Dockerfile.tmp .
rm -f Dockerfile.tmp 
docker tag ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}:${PRPL_DOCKER_IMAGE_TAG} ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}:latest
echo
docker images 
echo

# Cleanup
# If wanting to test docker build using our local sources
if [ "${ARG_USE_LOCAL_SOURCES}" == "TRUE" ] ; then
	rm -rf ${PRPL_TEMP_DIR}
	if [ -f ./prpl.srcs.tar.gz ] ; then
		rm -f prpl.srcs.tar.gz
	fi
fi

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
