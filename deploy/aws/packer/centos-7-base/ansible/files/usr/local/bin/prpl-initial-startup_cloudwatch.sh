#!/bin/bash
# Initial-startup of EC2 instance scripts.  Create config files for Amazon Cloudwatch Agent.
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
source /usr/local/etc/prpl-initial-startup_cloudwatch.config

[ ! -z ${PRPL_INIT_DEBUG_ENABLED:-} ] && set -x

if [ "${CLOUDWATCH_ENABLED}" == "FALSE" ] ; then
  log "Amazon CloudWatch agent disabled - skipping."
  systemctl disable amazon-cloudwatch-agent
  systemctl stop amazon-cloudwatch-agent
  exit 0
fi

# Validate our env vars
if [ "${CLOUDWATCH_REFRESH_INTERVAL_SECS}" == "" ] ; then
  logError "ERROR : missing value for variable 'CLOUDWATCH_REFRESH_INTERVAL_SECS'"
  err
fi

log "Configure Amazon CloudWatch agent"
# ....

log "Start Amazon CloudWatch agent"
# Also enable and start cloudwatch agent to pick up the new hostname (sometimes it fails to do this)
systemctl enable amazon-cloudwatch-agent
systemctl restart amazon-cloudwatch-agent
