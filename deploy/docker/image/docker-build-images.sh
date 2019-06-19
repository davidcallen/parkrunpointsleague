#!/bin/bash
#
# build and publish docker image
set -o errexit
set -o nounset

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| docker-build-images - Build all PRPL images                          |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  "    --make-jobs [-j]         - [optional] Number of make jobs, for parallelising build"
    echo  "    --use-local-source [-l]  - [optional] Use local source files (useful for testing)"
    echo  ""
    echo  " Examples"
    echo  "    ./docker-build-images.sh --make-jobs 4"
    echo  ""
    exit 1
}

ARG_USE_LOCAL_SOURCES=FALSE
ARG_MAKE_JOBS=2
ARG_RECOGNISED=FALSE
ARGS=$*
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "--help" -o  "$1" == "-h" ] ; then
		usage
	fi
	if [ "$1" == "--use-local-sources" -o "$1" == "-l" ] ; then
		ARG_USE_LOCAL_SOURCES=TRUE
		ARG_RECOGNISED=TRUE
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

cd ./prpl-base
./docker-build-image.sh

cd ../prpl
if [ "${ARG_USE_LOCAL_SOURCES}" == "TRUE" ] ; then
	./docker-build-image.sh --use-local-sources --make-jobs ${ARG_MAKE_JOBS}
else
	./docker-build-image.sh --make-jobs ${ARG_MAKE_JOBS}
fi
