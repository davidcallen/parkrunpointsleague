#!/bin/bash
# Initial-startup of EC2 instance scripts.  Start our Application
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

# Validate our env vars
# .... no validation needed as yet


if [ "${APP_SYSTEMD_SERVICE_NAME}" != "" ] ; then
  log "Enable the systemd services to run at boot time"
  systemctl enable ${APP_SYSTEMD_SERVICE_NAME}

  log "Start the systemd service"
  systemctl start ${APP_SYSTEMD_SERVICE_NAME}
fi