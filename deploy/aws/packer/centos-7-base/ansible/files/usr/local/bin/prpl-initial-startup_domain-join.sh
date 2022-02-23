#!/bin/bash
# Initial-startup of EC2 instance scripts.  Join the domain.
#
# Args :
#
# DOMAIN_HOST_NAME_SHORT_AD_FRIENDLY   =AD-friendly short (computer) name           e.g. AWS27164834
# DOMAIN_HOST_NAME                     =long host name                              e.g. prpl-core-nexus
# DOMAIN_HOST_FQDN                     =host FQDN                                   e.g. prpl-core-nexus.core.parkrunpointsleague.org
# DOMAIN_NAME                          =TLD                                         e.g. parkrunpointsleague.org
# DOMAIN_REALM_NAME                    =upper(TLD)                                  e.g. PARKRUNPOINTSLEAGUE.ORG
# DOMAIN_LOGIN_ALLOWED_GROUPS
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
source /usr/local/etc/prpl-initial-startup_domain-join.config

[ ! -z ${PRPL_INIT_DEBUG_ENABLED:-} ] && set -x

if [ "${DOMAIN_REALM_NAME}" != "" ] ; then
  log "Tweak /etc/hosts in preparation for Join AD Realm. Adding 127.0.0.1 ${DOMAIN_HOST_NAME_SHORT_AD_FRIENDLY}"
  # Using AD join approach of "realm join ...--computer-name=foobar"  requires a tweak to /etc/hosts
  # otherwise no DNS entry is added automatically to AD (for the $DOMAIN_HOST_NAME_SHORT_AD_FRIENDLY and
  # therefore cannot login via SSH etc... since DNS critical for AD)
  echo "127.0.0.1   ${DOMAIN_HOST_NAME_SHORT_AD_FRIENDLY}.${DOMAIN_NAME}   ${DOMAIN_HOST_NAME_SHORT_AD_FRIENDLY}" >> /etc/hosts

  log "Join AD Realm ${DOMAIN_REALM_NAME} with user ${DOMAIN_JOIN_USER_NAME}"
  echo -n "${DOMAIN_JOIN_USER_PASSWORD}" | realm join --user=${DOMAIN_JOIN_USER_NAME} --verbose \
    --computer-name=${DOMAIN_HOST_NAME_SHORT_AD_FRIENDLY} \
    --os-name=linux-centos --os-version=7 ${DOMAIN_REALM_NAME}

  log "Configure sssd service..."
  sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
  sed -i 's/fallback_homedir = \/home\/%u@%d/fallback_homedir = \/home\/%u/g' /etc/sssd/sssd.conf

  log "Restarting sssd service to apply config changes..."
  systemctl restart sssd

  realm deny --realm ${DOMAIN_NAME} --all
  IFS_ORIGINAL=${IFS}
  IFS=","
  for DOMAIN_LOGIN_ALLOWED_GROUP in ${DOMAIN_LOGIN_ALLOWED_GROUPS} ; do
    log "Permiting login to machine for AD group : '${DOMAIN_LOGIN_ALLOWED_GROUP}'"
    realm permit --realm ${DOMAIN_NAME} --groups "${DOMAIN_LOGIN_ALLOWED_GROUP}"
  done
  IFS=${IFS_ORIGINAL}

  log "Restarting sssd service to apply config changes..."
  systemctl restart sssd

  log "Configure SSH service to allow password authentication..."
  # authconfig modifies SSHD to disallow password - renable it so can AD login (and no ssh key management per user hassles)
  sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  service sshd reload

  log "Finished with domain joining."
fi