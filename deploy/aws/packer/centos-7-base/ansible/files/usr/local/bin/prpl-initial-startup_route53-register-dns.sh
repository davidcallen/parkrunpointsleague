#!/bin/bash
# Initial-startup of EC2 instance scripts.  Register our DNS on Route53
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
source /usr/local/etc/prpl-initial-startup_route53.config

[ ! -z ${PRPL_INIT_DEBUG_ENABLED:-} ] && set -x

if [ "${PRPL_ROUTE53_ENABLED}" == "" -o "${PRPL_ROUTE53_ENABLED}" == "FALSE" ] ; then
  log "Route53 support is disabled - skipping registering ec2 instance with DNS record on Route53."
  exit 0
fi

# Validate our env vars
if [ "${PRPL_ROUTE53_PRIVATE_HOSTED_ZONE_ID}" == "" ] ; then
  logError "ERROR : missing value for variable 'PRPL_ROUTE53_PRIVATE_HOSTED_ZONE_ID'"
  err
fi

if [ "${PRPL_ROUTE53_DIRECT_DNS_UPDATE_ENABLED}" == "TRUE" ] ; then
  PRIVATE_IP_ADDRESS=$(ip route get 1 | awk '{print $NF;exit}')
  HOSTNAME=$(hostname)
  TTL="600"

  aws route53 change-resource-record-sets \
    --hosted-zone-id ${PRPL_ROUTE53_PRIVATE_HOSTED_ZONE_ID} \
    --change-batch "{ \"Changes\": [ { \"Action\": \"UPSERT\", \"ResourceRecordSet\": { \"Name\": \"${HOSTNAME}\", \"Type\": \"A\", \"TTL\": ${TTL}, \"ResourceRecords\": [ { \"Value\": \"${PRIVATE_IP_ADDRESS}\" } ] } } ] }"

  log "Registered ec2 instance DNS record on Route53 Private Zone with hostname '${HOSTNAME}' and ip '${PRIVATE_IP_ADDRESS}'."
fi