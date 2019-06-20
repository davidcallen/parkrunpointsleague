#!/bin/bash
set -o errexit 
set -o nounset

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| create-db.sh - Create database and user                              |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  ""
    echo  " Examples"
    echo  "    ./create-db.sh --host prpl-mysql -p YYYYYYYYY -r XXXXXXXX -k "
    echo  ""
    exit 1
}

ARG_MYSQL_HOST=localhost
ARG_PRPL_PWD=
ARG_ROOT_PWD=
ARG_USE_KUBECTL_RUN=FALSE
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
	if [ "$1" == "--user-password" -o "$1" == "-p" ] ; then
		shift 1
		ARG_PRPL_PWD=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "$1" == "--root-password" -o "$1" == "-r" ] ; then
		shift 1
		ARG_ROOT_PWD=$1
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

if [ "${ARG_PRPL_PWD}" == "" ] ; then
	echo "ERROR: --user-password for mysql PRPL user pwd is needed"
	exit 1
fi
if [ "${ARG_ROOT_PWD}" == "" ] ; then
	echo "ERROR: --root-password for mysql root user pwd is needed"
	exit 1
fi
set -x
if [ "${ARG_USE_KUBECTL_RUN}" == "TRUE" ] ; then
	# ARG_MYSQL_HOST probably needs to be "prpl-mysql" if using std yaml to create mysql deployment
	sed "s/xxxxxxxx/${ARG_PRPL_PWD}/g" create-db.sql | kubectl run --stdin=true --rm --image=mysql:5.7 --restart=Never mysql-client -- mysql -h ${ARG_MYSQL_HOST} -u root -p${ARG_ROOT_PWD}
else
	sed "s/xxxxxxxx/${ARG_PRPL_PWD}/g" create-db.sql | mysql -h ${ARG_MYSQL_HOST} -u root --password=${ARG_ROOT_PWD} -B 
fi

# Useful for connecting to and inspecting database pod :
#   kubectl run -it --rm --image=mysql:5.7 --restart=Never mysql-client -- mysql -h prpl-mysql -u root -p
#
#   kubectl run -it --rm --image=mysql:5.7 --restart=Never mysql-client -- mysql -h prpl-mysql -u PRPL --database=PRPL -p
