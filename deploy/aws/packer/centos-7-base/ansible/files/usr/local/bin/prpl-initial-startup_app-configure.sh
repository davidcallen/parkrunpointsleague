#!/bin/bash
# Initial-startup of EC2 instance scripts.  Configure our Application and its linux user
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
source /usr/local/etc/prpl-initial-startup_app.config

[ ! -z ${PRPL_INIT_DEBUG_ENABLED:-} ] && set -x

if [ "${APP_LINUX_USER_NAME}" == "" ] ; then
  log "'APP_LINUX_USER_NAME' not set - skipping App configure"
  exit 0
fi

# Validate our env vars
if [ "${APP_LINUX_USER_GROUP}" == "" ] ; then
  logError "ERROR : missing value for variable 'APP_LINUX_USER_GROUP'"
  err
fi

log "Checking ownership on User's SSH files"
APP_USER_HOME_PATH=$(getent passwd ${APP_LINUX_USER_NAME} | cut -d ':' -f 6)
if [ "${APP_USER_HOME_PATH}" != "" ] ; then
  if [ ! -d ${APP_USER_HOME_PATH}/.ssh ] ; then
    mkdir ${APP_USER_HOME_PATH}/.ssh
    chmod 700 ${APP_USER_HOME_PATH}/.ssh
    chown ${APP_LINUX_USER_NAME}:${APP_LINUX_USER_GROUP} ${APP_USER_HOME_PATH}/.ssh
  fi
  if [ ! -f ${APP_USER_HOME_PATH}/.ssh/authorized_keys ] ; then
    touch ${APP_USER_HOME_PATH}/.ssh/authorized_keys
    if [ "${APP_SSH_PUBLIC_KEY}" != "" ] ; then
      log "Adding User's public SSH key to authorized list"
      echo "${APP_SSH_PUBLIC_KEY}" >> ${APP_USER_HOME_PATH}/.ssh/authorized_keys
    fi
    chmod 600 ${APP_USER_HOME_PATH}/.ssh/authorized_keys
    chown ${APP_LINUX_USER_NAME}:${APP_LINUX_USER_GROUP} ${APP_USER_HOME_PATH}/.ssh/authorized_keys
  fi
fi
