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

cd ./prpl-base
./docker-build-image.sh

cd ../prpl
if [ "${ARG_USE_LOCAL_SOURCES}" == "TRUE" ] ; then
	./docker-build-image.sh --use-local-sources
else
	./docker-build-image.sh
fi
