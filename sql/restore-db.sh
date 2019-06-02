#!/bin/bash
set -o errexit 
set -o nounset

ARG_PRPL_PWD=
ARG_DB_DUMP_FILE=

ARG_RECOGNISED=FALSE
ARGS=$*

# Check all args up front for early validation, since processing can take some time.
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "--help" -o  "$1" == "-h" ] ; then
		usage
	fi
	if [ "$1" == "--password" -o "$1" == "-p" ] ; then
		shift 1
		ARG_PRPL_PWD=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "$1" == "--db-file" -o "$1" == "-f" ]; then
		shift 1
		ARG_DB_DUMP_FILE=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "Invalid args : Unknown argument \"${1}\"."
		err 1
	fi
	shift
done


if [ "${ARG_DB_DUMP_FILE}" == "" ] ; then
	echo "ERROR: --db-file for the mysql database dump file is required."
	exit 1
fi
if [ ! -f "${ARG_DB_DUMP_FILE}" ] ; then
	echo "ERROR: --db-file for the mysql database dump file is not found."
	exit 1
fi
if [ "${ARG_PRPL_PWD}" == "" ] ; then
	echo "ERROR: --password for mysql PRPL user pwd is needed"
	exit 1
fi


cat ${ARG_DB_DUMP_FILE} | mysql -h localhost -u PRPL --password=${ARG_PRPL_PWD} -B 
