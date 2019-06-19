#!/bin/bash
#
# build and publish docker image
set -o errexit
set -o nounset

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
		echo "Invalid args : Unknown argument \"${1}\"."
		err 1
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
