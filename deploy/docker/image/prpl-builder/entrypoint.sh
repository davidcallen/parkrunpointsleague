#!/bin/sh
#
#
set -o errexit

echo "DOCKER_IMAGE_TAG=`cat /DOCKER_IMAGE_TAG`"
echo

# Input args :
# PRPL_SLEEP_SECS			= 5
# PRPL_SLEEP_TIMES			= 10

echo PRPL_SLEEP_SECS=${PRPL_SLEEP_SECS}
echo PRPL_SLEEP_TIMES=${PRPL_SLEEP_TIMES}

echo "Environment : "
env

PRPL_LOOPS=0
while(true) ; do
	echo "Sleeping..."
	sleep ${PRPL_SLEEP_SECS}

	PRPL_LOOPS=`expr ${PRPL_LOOPS} + 1`
	if [ ${PRPL_LOOPS} -ge ${PRPL_SLEEP_TIMES} ] ; then
		break
	fi
done

echo "PRPL finished"
