#!/bin/bash
# Initial-startup of EC2 instance scripts.  Initialise our Application (Nexus-specific)
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
# source /usr/local/etc/prpl-initial-startup_mount-file-system.config

[ ! -z ${PRPL_INIT_DEBUG_ENABLED:-} ] && set -x

# Validate our env vars
if [ "${APP_NEXUS_JENKINS_USER_PASSWORD_SECRET_ID}" == "" ] ; then
  logError "ERROR : missing value for variable 'APP_NEXUS_JENKINS_USER_PASSWORD_SECRET_ID'"
  err
fi
if [ "${APP_ADMIN_USER_PASSWORD_SECRET_ID}" == "" ] ; then
  logError "ERROR : missing value for variable 'APP_LINUX_USER_GROUP'"
  err
fi

#
## Get our config files from s3 bucket (too large to pass via user-data), for loading into Nexus
#aws s3 cp ${APP_CONFIG_S3_BUCKET_NAME}/Nexus.yaml ${FILE_SYSTEM_MOUNT_TARGET}
#chown ${APP_LINUX_USER_NAME}:${APP_LINUX_USER_GROUP} ${FILE_SYSTEM_MOUNT_TARGET}/Nexus.yaml
#chmod 0770 ${FILE_SYSTEM_MOUNT_TARGET}/Nexus.yaml

if [ "${APP_SYSTEMD_SERVICE_NAME}" != "" ] ; then
  log "Enable the systemd services to run at boot time"
  systemctl enable ${APP_SYSTEMD_SERVICE_NAME}

  START_CHECK_FROM_LOG_LINE=0
  if [ -f /var/nexus/log/nexus.log ] ; then
    START_CHECK_FROM_LOG_LINE=$(cat /var/nexus/log/nexus.log | wc -l)
    START_CHECK_FROM_LOG_LINE=$(( ${START_CHECK_FROM_LOG_LINE} + 1 ))
  fi

  log "Start the systemd service"
  systemctl start ${APP_SYSTEMD_SERVICE_NAME}

  # Check if nexus has rotated the log file, by checking the new line count
  CHECK_LOG_LINE_COUNT=$(cat /var/nexus/log/nexus.log | wc -l)
  CHECK_LOG_LINE_COUNT=$(( ${CHECK_LOG_LINE_COUNT} + 1 ))
  if [ ${START_CHECK_FROM_LOG_LINE} -gt ${CHECK_LOG_LINE_COUNT} ] ; then
    START_CHECK_FROM_LOG_LINE=0
  fi

  # Wait for Nexus to finish starting, before we can delete files
  WAIT_CHECK_COUNT=0
  WAIT_LIMIT_SECS=3000  # Nexus can easily take 5 mins to startup, even with empty repos !
  while true ; do
    CHECK_SERVICE_STARTED=$(tail -n +${START_CHECK_FROM_LOG_LINE} /var/nexus/log/nexus.log | grep '^Started Sonatype Nexus' || true)
    if [ "${CHECK_SERVICE_STARTED}" != "" ] ; then
      log "Nexus is fully up and running. Can now run config scripts..."
      break
    fi
    WAIT_CHECK_COUNT=$(( ${WAIT_CHECK_COUNT} + 1 ))
    if [ ${WAIT_CHECK_COUNT} -gt ${WAIT_LIMIT_SECS} ] ; then
      logError "Nexus is NOT fully up and running. Will leave config-as-code files"
      err
    fi
    log "Waiting for Nexus to be fully up and running before deleting config-as-code [${WAIT_CHECK_COUNT} of ${WAIT_LIMIT_SECS}] ..."
    sleep 2
  done
fi

# Call groovy scripts using our default admin password that is baked into the AMI. Then change it....

# Create jenkins user
NEXUS_JENKINS_USER_PASSWORD=$(aws secretsmanager get-secret-value --region=${AWS_REGION} --secret-id ${APP_NEXUS_JENKINS_USER_PASSWORD_SECRET_ID} --query SecretString --output text)
echo "[ { " \
"  \"state\": \"present\"," \
"  \"username\": \"jenkins\"," \
"  \"first_name\": \"jenkins\"," \
"  \"last_name\": \"CI\"," \
"  \"email\": \"devops@parkrunpointsleague.org\"," \
"  \"password\": \"${NEXUS_JENKINS_USER_PASSWORD}\"," \
"  \"roles\": [" \
"    \"jenkins\"" \
"   ]" \
"}]" > params.json
curl --silent --fail -v -X POST -u admin:nkl12390uckbj134gvg --header "Content-Type: text/plain" 'http://localhost:8081/service/rest/v1/script/setup_users_from_list/run' -d @params.json
shred -u params.json
unset NEXUS_JENKINS_USER_PASSWORD

# Change admin user password - get new one from AWS Secrets Manager (ASM)
ADMIN_USER_PASSWORD=$(aws secretsmanager get-secret-value --region=${AWS_REGION} --secret-id ${APP_ADMIN_USER_PASSWORD_SECRET_ID} --query SecretString --output text)
echo "{ \"new_password\": \"${ADMIN_USER_PASSWORD}\" }" > params.json
curl --silent --fail -v -X POST -u admin:nkl12390uckbj134gvg --header "Content-Type: text/plain" 'http://localhost:8081/service/rest/v1/script/update_admin_password/run' -d @params.json
shred -u params.json
unset ADMIN_USER_PASSWORD


