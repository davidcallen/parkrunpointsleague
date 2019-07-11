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
    echo  "    --image-build-only [-i]  - [optional] Only build the image - no compiling of libraries into build-output directory"
    echo  ""
    echo  " Examples"
    echo  "    ./docker-build-image.sh --make-jobs 4"
    echo  ""
    exit 1
}

ARG_MAKE_JOBS=2
ARG_IMAGE_BUILD_ONLY=FALSE
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
START_PATH=`pwd`

# Common settings for build and publish docker images
PRPL_DOCKER_IMAGE_NAME=prpl-base
export PRPL_DOCKER_BUILD_DATE=`date`
export PRPL_DOCKER_IMAGE_TAG=`date +%Y%m%d%H%M%S`
echo ${PRPL_DOCKER_IMAGE_TAG} > DOCKER_IMAGE_TAG

echo "Building image ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME} for tag ${PRPL_DOCKER_IMAGE_TAG}"
echo

if [ "${ARG_IMAGE_BUILD_ONLY}" == "FALSE" ] ; then 
	[ -d build-output ] && rm -rf build-output
	mkdir build-output
	trap "[ -d ${START_PATH}/build-output ] && rm -rf ${START_PATH}/build-output" EXIT

	echo '----------------------------------- Build libtidy --------------------------------------------'
	docker run --rm --volume=$PWD/build-output:/prpl --volume=/prpl-srcs prpl-builder:latest /bin/sh -c 'mkdir -p /prpl-srcs/ && cd /prpl-srcs \
		&& git clone https://github.com/htacg/tidy-html5 \
		&& cd tidy-html5 \
		&& cd build/cmake \
		&& cmake ../.. -DCMAKE_INSTALL_PREFIX=/prpl -DCMAKE_BUILD_TYPE=Release \
		&& make install \
		&& chmod -R 777 /prpl \
		&& ls -la /prpl/*'
		
	ls -la $PWD/build-output

	echo '----------------------------------- Build gumbo --------------------------------------------'
	docker run --rm --volume=$PWD/build-output:/prpl --volume=/prpl-srcs prpl-builder:latest /bin/sh -c "mkdir -p /prpl-srcs/ && cd /prpl-srcs \
		&& git clone https://github.com/google/gumbo-parser \
		&& cd gumbo-parser \
		&& ./autogen.sh \
		&& ./configure --prefix=/prpl \
		&& make -j ${ARG_MAKE_JOBS} \
		&& make install \
		&& chmod -R 777 /prpl \
		&& ls -la /prpl/"

	ls -la $PWD/build-output

	echo '----------------------------------- Build poco --------------------------------------------'
	docker run --rm --volume=$PWD/build-output:/prpl --volume=/prpl-srcs prpl-builder:latest /bin/sh -c "mkdir -p /prpl-srcs/ && cd /prpl-srcs \
		&& export LD_LIBRARY_PATH=/lib64:/usr/lib64:/usr/local/lib64:/lib:/usr/lib:/usr/local/lib \
		&& git clone -b poco-1.7.8 https://github.com/pocoproject/poco.git \
		&& cd poco \
		&& ./configure --prefix=/prpl --everything --omit=Data/ODBC,Data/SQLite,PDF,MongoDB,ApacheConnector,CppParser,PageCompiler,ProGen,SevenZip --no-samples --no-tests \
		&& echo Making with ${ARG_MAKE_JOBS} jobs... \
		&& make -j ${ARG_MAKE_JOBS} \
		&& make install \
		&& chmod -R 777 /prpl \
		&& ls -la /prpl/"

	ls -la $PWD/build-output
fi

echo -e "\n----------------------------------- Build image  ---------------------------------------------\n"
docker rmi ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME} || true
echo
docker build \
	--tag=${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}:${PRPL_DOCKER_IMAGE_TAG} \
	--file=./Dockerfile .
docker tag ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}:${PRPL_DOCKER_IMAGE_TAG} ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME}:latest

echo
docker images

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

if [ "${PRPL_DOCKER_REGISTRY}" != "" ] ; then
	echo -e "\n--------------------------------  Registry contents ------------------------------------\n"
	curl -X GET https://${PRPL_DOCKER_REGISTRY}v2/_catalog 2>/dev/null | python -m json.tool
fi

echo -e "\n----------"
echo "Finished image ${PRPL_DOCKER_REGISTRY}${PRPL_DOCKER_IMAGE_NAME} tag ${PRPL_DOCKER_IMAGE_TAG} at `date` (started at ${START_DATE})"
echo 
