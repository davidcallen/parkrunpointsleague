#!/bin/bash
# Initial-startup of EC2 instance scripts. Will call script for each component
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

log "Starting"
/usr/local/bin/prpl-initial-startup_motd.sh

log "Register DNS with Route53"
/usr/local/bin/prpl-initial-startup_route53-register-dns.sh

log "Create the config for the Telegraf Agent (and then restart its service)..."
/usr/local/bin/prpl-initial-startup_telegraf.sh

log "Create the config for the Amazon Cloudwatch Agent (and then restart its service)..."
/usr/local/bin/prpl-initial-startup_cloudwatch.sh

log "Mount persistent filesystem (EBS/EFS)..."
/usr/local/bin/prpl-initial-startup_mount-file-system.sh

log "Configure App environment ..."
/usr/local/bin/prpl-initial-startup_app-configure.sh
/usr/local/bin/prpl-initial-startup_app-configure-custom.sh

log "Enable+start App service..."
/usr/local/bin/prpl-initial-startup_app-start.sh

log "Finished"