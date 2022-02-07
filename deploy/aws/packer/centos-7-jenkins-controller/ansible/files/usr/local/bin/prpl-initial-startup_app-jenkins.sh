#!/bin/bash
# Initial-startup of EC2 instance scripts.  Initialise our Application (Jenkins-specific)
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
source /usr/local/etc/prpl-initial-startup_mount-file-system.config

[ ! -z ${PRPL_INIT_DEBUG_ENABLED:-} ] && set -x

# Validate our env vars
if [ "${APP_LINUX_USER_NAME}" == "" ] ; then
  logError "ERROR : missing value for variable 'APP_LINUX_USER_NAME'"
  err
fi
if [ "${APP_LINUX_USER_GROUP}" == "" ] ; then
  logError "ERROR : missing value for variable 'APP_LINUX_USER_GROUP'"
  err
fi
if [ "${APP_CONFIG_S3_BUCKET_NAME}" == "" ] ; then
  logError "ERROR : missing value for variable 'APP_CONFIG_S3_BUCKET_NAME'"
  err
fi
if [ "${FILE_SYSTEM_MOUNT_TARGET}" == "" ] ; then
  logError "ERROR : missing value for variable 'FILE_SYSTEM_MOUNT_TARGET'"
  err
fi
if [ "${APP_JENKINS_NEXUS_USER_PASSWORD_SECRET_ID}" == "" ] ; then
  logError "ERROR : missing value for variable 'APP_JENKINS_NEXUS_USER_PASSWORD_SECRET_ID'"
  err
fi
if [ "${APP_ADMIN_USER_PASSWORD_SECRET_ID}" == "" ] ; then
  logError "ERROR : missing value for variable 'APP_ADMIN_USER_PASSWORD_SECRET_ID'"
  err
fi

# Get our config files from s3 bucket (too large to pass via user-data), for loading into Jenkins
aws s3 cp ${APP_CONFIG_S3_BUCKET_NAME}/jenkins.yaml ${FILE_SYSTEM_MOUNT_TARGET}
chown ${APP_LINUX_USER_NAME}:${APP_LINUX_USER_GROUP} ${FILE_SYSTEM_MOUNT_TARGET}/jenkins.yaml
chmod 0770 ${FILE_SYSTEM_MOUNT_TARGET}/jenkins.yaml

JENKINS_NEXUS_USER_PASSWORD=$(aws secretsmanager get-secret-value --region=${AWS_REGION} --secret-id ${APP_JENKINS_NEXUS_USER_PASSWORD_SECRET_ID} --query SecretString --output text)
sed -i "s/<<JENKINS_NEXUS_USER_PASSWORD>>/${JENKINS_NEXUS_USER_PASSWORD}/g" ${FILE_SYSTEM_MOUNT_TARGET}/jenkins.yaml
unset JENKINS_NEXUS_USER_PASSWORD

# Change admin user password - get it from AWS Secrets Manager (ASM)
ADMIN_USER_PASSWORD=$(aws secretsmanager get-secret-value --region=${AWS_REGION} --secret-id ${APP_ADMIN_USER_PASSWORD_SECRET_ID} --query SecretString --output text)
sed 's/{{ jenkins_admin_username }}/admin/g' /var/lib/jenkins/basic-security.groovy.template | \
  sed "s/{{ jenkins_admin_password }}/${ADMIN_USER_PASSWORD}/g" > /var/lib/jenkins/init.groovy.d/basic-security.groovy
chown ${APP_LINUX_USER_NAME}:${APP_LINUX_USER_GROUP} /var/lib/jenkins/init.groovy.d/basic-security.groovy
chmod 0770 /var/lib/jenkins/init.groovy.d/basic-security.groovy
unset ADMIN_USER_PASSWORD

# Note : at Jenkins startup it will :
#  1) the JCasC jenkins.yaml file will be applied to the jenkins config.
#  2) the basic-security.groovy will be run within Jenkins to set the admin password
if [ "${APP_SYSTEMD_SERVICE_NAME}" != "" ] ; then
  log "Enable the systemd services to run at boot time"
  systemctl enable ${APP_SYSTEMD_SERVICE_NAME}

  START_CHECK_FROM_LOG_LINE=0
  if [ -f /var/log/jenkins/jenkins.log ] ; then
    START_CHECK_FROM_LOG_LINE=$(cat /var/log/jenkins/jenkins.log | wc -l)
    START_CHECK_FROM_LOG_LINE=$(( ${START_CHECK_FROM_LOG_LINE} + 1 ))
  fi

  log "Start the systemd service"
  systemctl start ${APP_SYSTEMD_SERVICE_NAME}

  # Wait for Jenkins to finish starting, before we can delete files
  WAIT_CHECK_COUNT=0
  WAIT_LIMIT_SECS=300
  while true ; do
    CHECK_SERVICE_STARTED=$(tail -n +${START_CHECK_FROM_LOG_LINE} /var/log/jenkins/jenkins.log | grep 'Jenkins is fully up and running' || true)
    if [ "${CHECK_SERVICE_STARTED}" != "" ] ; then
      log "Jenkins is fully up and running. Can now delete config-as-code files."
      break
    fi
    WAIT_CHECK_COUNT=$(( ${WAIT_CHECK_COUNT} + 1 ))
    if [ ${WAIT_CHECK_COUNT} -gt ${WAIT_LIMIT_SECS} ] ; then
      logError "Jenkins is NOT fully up and running. Will leave config-as-code files"
      err
    fi
    log "Waiting for Jenkins to be fully up and running before deleting config-as-code [${WAIT_CHECK_COUNT} of ${WAIT_LIMIT_SECS}] ..."
    sleep 2
  done
fi

# Delete our JCasC file - otherwise it will be reloaded on jenkins startup and could loose latest config....
#   ... or this may actually be a desirable thing (i.e. "immutable" Jenkins) !
# TODO : decide on whether to delete our JCasC file
shred -u ${FILE_SYSTEM_MOUNT_TARGET}/jenkins.yaml

# Delete admin password script to prevent password hanging around in clear text
[ -f /var/lib/jenkins/init.groovy.d/basic-security.groovy ] && shred -u /var/lib/jenkins/init.groovy.d/basic-security.groovy
