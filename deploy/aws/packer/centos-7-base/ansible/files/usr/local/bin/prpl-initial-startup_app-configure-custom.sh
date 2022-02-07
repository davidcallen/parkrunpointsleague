#!/bin/bash
# Initial-startup of EC2 instance scripts.  Custom configuration for our Application.
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

# ... override this custom configure script if needed in app-specific AMI (based from this AMI)