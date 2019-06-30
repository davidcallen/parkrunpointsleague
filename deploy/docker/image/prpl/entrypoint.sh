#!/bin/sh
#
#
set -o errexit

echo "DOCKER_IMAGE_TAG=`cat /DOCKER_IMAGE_TAG`"
echo

# Input args :
# PRPL_DEBUG_STAY_ALIVE_SLEEP_SECS			= 5
# PRPL_DEBUG_STAY_ALIVE_SLEEP_TIMES			= 10
# PRPL_DEBUG_STAY_ALIVE						= FALSE

echo PRPL_DEBUG_STAY_ALIVE_SLEEP_SECS=${PRPL_DEBUG_STAY_ALIVE_SLEEP_SECS}
echo PRPL_DEBUG_STAY_ALIVE_SLEEP_TIMES=${PRPL_DEBUG_STAY_ALIVE_SLEEP_TIMES}
echo PRPL_DEBUG_STAY_ALIVE=${PRPL_DEBUG_STAY_ALIVE}

echo "Environment : "
env

#----------------------------------------------------------------------------------
# Check the mysql server is alive and functioning
#
# args:
# 1 = ARG_PRPL_MYSQL_HOST			The server hostname
# 2 = ARG_PRPL_MYSQL_USER           The user to connect with
# 3 = ARG_PRPL_MYSQL_PWD    		The user password
# 4 = ARG_PRPL_MYSQL_PORT			[optional] The server port
#
function check_database_server_alive_mysql()
{
	CHECK_DATABASE_SERVER_ALIVE_MYSQL_EXIT_CODE=0

	# input args
	ARG_PRPL_MYSQL_HOST=$1
	ARG_PRPL_MYSQL_USER=$2
	ARG_PRPL_MYSQL_PWD=$3
	ARG_PRPL_MYSQL_PORT=3306
	if [ $# -gt 3 ] ; then
		ARG_PRPL_MYSQL_PORT=$4
	fi

	# Validate input args
	if [ "${ARG_PRPL_MYSQL_HOST}" == "" ] ; then
		echo "ERROR: invalid args for check_database_server_alive_mysql function. Host is empty."
		CHECK_DATABASE_SERVER_ALIVE_MYSQL_EXIT_CODE=1
		return 0
	fi
	
	if [ "${PRPL_MYSQL_HOST}" != "EMBEDDED" ] ; then
		local LOOP_MAX=10
		for LOOP in `seq ${LOOP_MAX}` ; do
			echo "Checking if mysql database server is alive [host=${ARG_PRPL_MYSQL_HOST}, port=${ARG_PRPL_MYSQL_PORT}, attempt=${LOOP}]"

			#set_shell_option errexit off
            set +o errexit
			mysqladmin ping --host=${ARG_PRPL_MYSQL_HOST} --port=${ARG_PRPL_MYSQL_PORT} --user=${ARG_PRPL_MYSQL_USER} --password=${ARG_PRPL_MYSQL_PWD}
			
			if [ $? -eq 0 ] ; then
                set -o errexit
				#set_shell_option errexit ${SET_SHELL_OPTION_PRIOR_VALUE}
				break
			else
                set -o errexit
				#set_shell_option errexit ${SET_SHELL_OPTION_PRIOR_VALUE}
				if [ ${LOOP} -eq ${LOOP_MAX} ] ; then
					echo "ERROR : mysql server is not alive [host=${ARG_PRPL_MYSQL_HOST}, port=${ARG_PRPL_MYSQL_PORT}]"
					CHECK_DATABASE_SERVER_ALIVE_MYSQL_EXIT_CODE=1
					break;
				fi
				echo "Checking if mysql database server is alive has failed. Sleeping for 5 seconds and then retrying..."
				sleep 2
			fi
		done
	fi

	return 0
}

# Configure XML file
cd /prpl/bin
if [ ! -f prpld.xml ] ; then
	echo "Creating prpld.xml..."
	set -x
	cp ../doc/prpld-example-mkpc004.xml prpld.xml
	# TODO : Change prpld to accept env vars which override the XML file - so no sed-ing needed
	if [ "${PRPL_HTTP_PORT}" != "" ] ; then
		xmlstarlet ed --inplace -P -S -u "/config/http/port" -v "${PRPL_HTTP_PORT}" prpld.xml
	fi
	if [ "${PRPL_DATABASE_HOST}" != "" ] ; then
		xmlstarlet ed --inplace -P -S -u "/config/database/host" -v "${PRPL_DATABASE_HOST}" prpld.xml
	fi
	if [ "${PRPL_DATABASE_PORT}" != "" ] ; then
		xmlstarlet ed --inplace -P -S -u "/config/database/port" -v "${PRPL_DATABASE_PORT}" prpld.xml
	fi
	if [ "${PRPL_DATABASE_NAME}" != "" ] ; then
		xmlstarlet ed --inplace -P -S -u "/config/database/name" -v "${PRPL_DATABASE_NAME}" prpld.xml
	fi
	# TODO : move into secrets
	if [ "${PRPL_DATABASE_PWD}" != "" ] ; then
		xmlstarlet ed --inplace -P -S -u "/config/database/password" -v "${PRPL_DATABASE_PWD}" prpld.xml
	fi
	# sed -i "s/<port>8080</port>/${PRPL_HTTP_PORT}/g" prpld.xml
fi

# Wait until mysql server becomes available
#echo -e "\n----------------------------------  MySQL : wait till server ready ---------------------------------------\n"
#check_database_server_alive_mysql ${PRPL_DATABASE_HOST} root ${PRPL_DATABASE_PWD} ${PRPL_DATABASE_PORT}
#if [ ${CHECK_DATABASE_SERVER_ALIVE_MYSQL_EXIT_CODE} -ne 0 ] ; then
#	exit 1
#fi

export LD_LIBRARY_PATH=/lib64:/usr/lib64:/usr/local/lib64:/lib:/usr/lib:/usr/local/lib:/prpl/lib

echo "Running prpld..."
./prpld

if [ "${PRPL_DEBUG_STAY_ALIVE}" != "" ] ; then
	PRPL_LOOPS=0
	while(true) ; do
		echo "DEBUG : Staying alive for inspection..."
		sleep ${PRPL_DEBUG_STAY_ALIVE_SLEEP_SECS}

		PRPL_LOOPS=`expr ${PRPL_LOOPS} + 1`
		if [ ${PRPL_LOOPS} -ge ${PRPL_DEBUG_STAY_ALIVE_SLEEP_TIMES} ] ; then
			break
		fi
	done
fi

echo "PRPL finished"
