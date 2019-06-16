#!/bin/bash
set -o errexit
set -o nounset

ARG_MYSQL_HOST=localhost
ARG_ROOT_PWD=
ARG_RECOGNISED=FALSE
ARGS=$*
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
	if [ "$1" == "--root-password" -o "$1" == "-r" ] ; then
		shift 1
		ARG_ROOT_PWD=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "Invalid args : Unknown argument \"${1}\"."
		err 1
	fi
	shift
done

if [ "${ARG_ROOT_PWD}" == "" ] ; then
	echo "ERROR: mysql root user pwd is needed"
	exit 1
fi

cat drop-db.sql | mysql -h ${ARG_MYSQL_HOST} -u root --password=${ARG_ROOT_PWD} -B 
