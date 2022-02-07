#!/bin/bash
# Initial-startup of EC2 instance scripts.  Initialise our Application, its User, and start the app service
#
set -o errexit
set -o nounset
function log()
{
	echo "$(date '+%Y%m%d %H:%M:%S') : prpl-initial-startup : INFO  : ${1}"
}
function logError()
{
	echo "$(date '+%Y%m%d %H:%M:%S') : prpl-initial-startup : ERROR : ${1}"
}
function err()
{
  logError "in $0"
  exit 1
}
trap err ERR

source /usr/local/etc/prpl-initial-startup.config

[ ! -z ${PRPL_INIT_DEBUG_ENABLED:-} ] && set -x

# Validate our env vars
if [ "${PRPL_MOTD_MSG}" == "" ] ; then
  logError "ERROR : missing value for variable 'PRPL_MOTD_MSG'"
  err
fi

sed -i "s/^Welcome to ParkRun Points League$/${PRPL_MOTD_MSG}/g" /etc/motd