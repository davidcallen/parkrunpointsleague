#!/bin/bash
#
# build and publish docker image
set -o errexit
set -o nounset

ARG_USE_LOCAL_SOURCES=FALSE
ARG_RECOGNISED=FALSE
ARGS=$*
# Check all args up front for early validation, since processing can take some time.
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "--help" -o  "$1" == "-h" ] ; then
		usage
	fi
	if [ "$1" == "--use-local-sources" -o "$1" == "-l" ] ; then
		ARG_USE_LOCAL_SOURCES=TRUE
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "Invalid args : Unknown argument \"${1}\"."
		err 1
	fi
	shift
done

START_DATE=`date`
set -x

source ../../docker-config.sh

# Common settings for build and publish docker images
export PRPL_DOCKER_BUILD_DATE=`date`
export PRPL_DOCKER_IMAGE_TAG=`date +%Y%m%d%H%M%S`
echo ${PRPL_DOCKER_IMAGE_TAG} > DOCKER_IMAGE_TAG
export PRPL_BASE_DOCKER_IMAGE_TAG=`cat ../prpl-base/DOCKER_IMAGE_TAG`
PRPL_DOCKER_IMAGE_NAME=prpl

echo "Building image ${PRPL_DOCKER_IMAGE_NAME} for tag ${PRPL_DOCKER_IMAGE_TAG}"
echo

# If wanting to test docker build using our local sources
if [ "${ARG_USE_LOCAL_SOURCES}" == "TRUE" ] ; then
	set -x
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
cp Dockerfile Dockerfile.tmp
sed -i "s/<<PRPL_BASE_DOCKER_IMAGE_TAG>>/${PRPL_BASE_DOCKER_IMAGE_TAG}/g" Dockerfile
docker build -t ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}:${PRPL_DOCKER_IMAGE_TAG} -t ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}:latest .
mv Dockerfile.tmp Dockerfile
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
