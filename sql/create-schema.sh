#!/bin/bash
set -o errexit
set -o nounset

ARG_MYSQL_HOST=localhost
ARG_PRPL_PWD=
ARG_RECOGNISED=FALSE
ARGS=$*
# Check all args up front for early validation, since processing can take some time.
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "--help" -o  "$1" == "-h" ] ; then
		usage
	fi
	if [ "$1" == "--host" ] ; then
		shift 1
		ARG_MYSQL_HOST=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "$1" == "--user-password" -o "$1" == "-p" ] ; then
		shift 1
		ARG_PRPL_PWD=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "Invalid args : Unknown argument \"${1}\"."
		err 1
	fi
	shift
done

if [ "${ARG_PRPL_PWD}" == "" ] ; then
	echo "ERROR: mysql PRPL user pwd is needed"
	exit 1
fi

cat create-schema.sql | mysql -h ${ARG_MYSQL_HOST} -u PRPL --password=${ARG_PRPL_PWD} -B 
