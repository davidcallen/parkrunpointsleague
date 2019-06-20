#!/bin/bash
set -o errexit 
set -o nounset

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| restore-db.sh - Restore database from backup SQL file                |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  ""
    echo  " Examples"
    echo  "    ./restore-db.sh --host prpl-mysql --db-file ./db-backups/prpl-db-backup.sql.tar.gz -p XXXXXXXXX -k"
    echo  ""
    exit 1
}

ARG_MYSQL_HOST=localhost
ARG_PRPL_PWD=
ARG_DB_DUMP_FILE=
ARG_USE_KUBECTL_RUN=FALSE
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
	if [ "$1" == "--use-kubectl-run" -o "$1" == "-k" ] ; then
		ARG_USE_KUBECTL_RUN=TRUE
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "ERROR: Invalid args : Unknown argument \"${1}\"."
		exit 1
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

if [ "${ARG_DB_DUMP_FILE: -7}" == ".tar.gz" ] ; then
	if [ "${ARG_USE_KUBECTL_RUN}" == "TRUE" ] ; then
		# ARG_MYSQL_HOST probably needs to be "prpl-mysql" if using std yaml to create mysql deployment
		tar --to-stdout -xvf ${ARG_DB_DUMP_FILE} | kubectl run --stdin=true --rm --image=mysql:5.7 --restart=Never mysql-client -- mysql -h ${ARG_MYSQL_HOST} -u PRPL -p${ARG_PRPL_PWD} -B --
	else
		tar --to-stdout -xvf ${ARG_DB_DUMP_FILE} | mysql -h ${ARG_MYSQL_HOST} -u PRPL --password=${ARG_PRPL_PWD} -B 
	fi
else 
	if [ "${ARG_USE_KUBECTL_RUN}" == "TRUE" ] ; then
		# ARG_MYSQL_HOST probably needs to be "prpl-mysql" if using std yaml to create mysql deployment
		cat ${DB_DUMP_FILE} | kubectl run --stdin=true --rm --image=mysql:5.7 --restart=Never mysql-client -- mysql -h ${ARG_MYSQL_HOST} -u PRPL -p${ARG_PRPL_PWD} -B --
	else
		cat ${DB_DUMP_FILE} | mysql -h ${ARG_MYSQL_HOST} -u PRPL --password=${ARG_PRPL_PWD} -B 
	fi
fi
