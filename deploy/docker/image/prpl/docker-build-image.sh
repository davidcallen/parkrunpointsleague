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
    echo  "    --base-tag [-t]          - [optional] The image tag for prpl-base"
    echo  "    --make-jobs [-j]         - [optional] Number of make jobs, for parallelising build"
    echo  "    --use-local-source [-l]  - [optional] Use local source files (useful for testing)"
    echo  "    --image-build-only [-i]  - [optional] Only build the image - no compiling of libraries into build-output directory"
    echo  ""
    echo  " Examples"
    echo  "    ./docker-build-image.sh --make-jobs 4"
    echo  ""
    exit 1
}

ARG_USE_PRPL_BASE_IMAGE_TAG=latest
ARG_MAKE_JOBS=2
ARG_USE_LOCAL_SOURCES=FALSE
ARG_IMAGE_BUILD_ONLY=FALSE
ARG_RECOGNISED=FALSE
ARGS=$*
# Check all args up front for early validation, since processing can take some time.
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "--help" -o  "$1" == "-h" ] ; then
		usage
	fi
	if [ "$1" == "--base-tag" -o "$1" == "-t" ] ; then
		shift 1
		ARG_USE_PRPL_BASE_IMAGE_TAG=$1
		ARG_RECOGNISED=TRUE
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
	if [ "$1" == "--image-build-only" -o  "$1" == "-i" ] ; then
		ARG_IMAGE_BUILD_ONLY=TRUE
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "ERROR: Invalid args : Unknown argument \"${1}\"."
		exit 1
	fi
	shift
done

START_DATE=`date`
START_PATH=${PWD}

[[ ! -v PRPL_DOCKER_REGISTRY ]] && echo "ERROR : docker build environment not set. Ensure you have done 'source docker-config.sh'" && exit 1

# Common settings for build and publish docker images
PRPL_DOCKER_IMAGE_NAME=prpl
export PRPL_DOCKER_BUILD_DATE=`date`
export PRPL_DOCKER_IMAGE_TAG=`date +%Y%m%d%H%M%S`
echo ${PRPL_DOCKER_IMAGE_TAG} > DOCKER_IMAGE_TAG
PRPL_BASE_DOCKER_IMAGE_TAG=`cat ../prpl-base/DOCKER_IMAGE_TAG`
if [ "${ARG_USE_PRPL_BASE_IMAGE_TAG}" != "" ] ; then
	PRPL_BASE_DOCKER_IMAGE_TAG=${ARG_USE_PRPL_BASE_IMAGE_TAG}
fi
export PRPL_BASE_DOCKER_IMAGE_TAG
PRPL_TEMP_DIR=

echo "Building image ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME} for tag ${PRPL_DOCKER_IMAGE_TAG}"
echo

if [ "${ARG_IMAGE_BUILD_ONLY}" == "FALSE" ] ; then 
	# If wanting to test docker build using our local sources
	if [ "${ARG_USE_LOCAL_SOURCES}" == "TRUE" ] ; then
		if [ -f prpl.srcs.tar.gz ] ; then
			rm -rf prpl.srcs.tar.gz
		fi
		PRPL_TEMP_DIR=`mktemp -d`
		tar --exclude='../../../../../prpl/src/poco' \
			--exclude='../../../../../prpl/data/*' \
			--exclude='../../../../../prpl/src/external/*' \
			--exclude='../../../../../prpl/bin/*' \
			--exclude='../../../../../prpl/lib' \
			--exclude='../../../../../prpl/include' \
			--exclude='.git' \
			--exclude='CMakeFiles' \
			--exclude='../../../../../prpl/src/exe/prpld/CMakeFiles' \
			--exclude='deploy' \
			--exclude='build-output' \
			-cf ${PRPL_TEMP_DIR}/prpl.srcs.tar.gz ../../../../../prpl 
		cp -r ${PRPL_TEMP_DIR}/prpl.srcs.tar.gz .

		trap "[ -d ${PRPL_TEMP_DIR} ] && rm -rf ${PRPL_TEMP_DIR}" EXIT
  fi

	#echo -e "\n----------------------------------- Stop container -------------------------------------------\n"
	#docker stop ${PRPL_DOCKER_IMAGE_NAME} || true
	#docker rm ${PRPL_DOCKER_IMAGE_NAME} || true
	#docker ps

	[ -d ${START_PATH}/build-output ] && rm -rf ${START_PATH}/build-output
	mkdir -p ${START_PATH}/build-output/libs
	cd ${START_PATH}/build-output

	trap "[ -d ${START_PATH}/build-output ] && rm -rf ${START_PATH}/build-output" EXIT

	echo -e '\n----------------------------------- Get lib dependancy binaries --------------------------------------\n'
	# Extract the libs from prpl-base image for use in this image build
	DOCKER_BASE_LIBS_ID=`docker create ${PRPL_DOCKER_REGISTRY}prpl-base:${ARG_USE_PRPL_BASE_IMAGE_TAG}`
	docker cp -a ${DOCKER_BASE_LIBS_ID}:/prpl-libs/include ${START_PATH}/build-output/libs
	docker cp -a ${DOCKER_BASE_LIBS_ID}:/prpl-libs/lib ${START_PATH}/build-output
	docker rm ${DOCKER_BASE_LIBS_ID}

	echo -e '\n----------------------------------- Build binaries--------------------------------------------\n'
	if [ "${ARG_USE_LOCAL_SOURCES}" == "TRUE" ] ; then
		mv ${PRPL_TEMP_DIR}/prpl.srcs.tar.gz ${START_PATH}/build-output
		cd ${START_PATH}/build-output
		tar xf prpl.srcs.tar.gz
		mv ${START_PATH}/build-output/prpl/* .
		rm -rf ${START_PATH}/build-output/prpl
		cd ..
		ls -al ${START_PATH}/build-output

		docker run --volume=${START_PATH}/build-output:/prpl ${PRPL_DOCKER_REGISTRY}prpl-builder:latest \
			/bin/sh -c "cd /prpl \
			&& cd /prpl/src \
			&& export LD_LIBRARY_PATH=/lib64:/usr/lib64:/usr/local/lib64:/lib:/usr/lib:/usr/local/lib:/prpl/lib \
			&& ./build.sh -clean -cpu ${ARG_MAKE_JOBS} && rm -rf /prpl/src/exe/prpld/CMakeFiles && rm -f /prpl/sql/db-backups/* \
			&& chmod -R 777 /prpl"
	else
		docker run --volume=${START_PATH}/build-output:/prpl ${PRPL_DOCKER_REGISTRY}prpl-builder:latest \
			/bin/sh -c "mkdir /prpl-libs && mv /prpl/* /prpl-libs/ && cd / \
			&& git clone https://github.com/davidcallen/parkrunpointsleague.git prpl \
			&& mv /prpl-libs/* /prpl \
			&& cd /prpl/src \
			&& export LD_LIBRARY_PATH=/lib64:/usr/lib64:/usr/local/lib64:/lib:/usr/lib:/usr/local/lib:/prpl/lib \
			&& ./build.sh -clean -cpu ${ARG_MAKE_JOBS} -v && rm -rf /prpl/src/exe/prpld/CMakeFiles && rm -f /prpl/sql/db-backups/* \
			&& chmod -R 777 /prpl"
	fi
fi

cd ${START_PATH}

echo -e "\n----------------------------------- Build image  ---------------------------------------------\n"
docker rmi ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME} || true
echo
docker build \
	--tag=${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}:${PRPL_DOCKER_IMAGE_TAG} \
	--file=./Dockerfile .
docker tag ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}:${PRPL_DOCKER_IMAGE_TAG} ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}:latest
echo
echo "REPOSITORY                        TAG                 IMAGE ID            CREATED             SIZE"
docker images | grep ${PRPL_DOCKER_IMAGE_NAME}
echo

# Cleanup
# If wanting to test docker build using our local sources
if [ "${ARG_USE_LOCAL_SOURCES}" == "TRUE" ] ; then
	[ -d ${PRPL_TEMP_DIR} ] && rm -rf ${PRPL_TEMP_DIR}
	if [ -f ./prpl.srcs.tar.gz ] ; then
		rm -f prpl.srcs.tar.gz
	fi
fi

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
echo "Finished image ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME} tag ${PRPL_DOCKER_IMAGE_TAG} at `date` (started at ${START_DATE})"
