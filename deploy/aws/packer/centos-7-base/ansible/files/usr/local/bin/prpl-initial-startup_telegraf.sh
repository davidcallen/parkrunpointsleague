#!/bin/bash
# Initial-startup of EC2 instance scripts.  Create config files for Telegraf Agent.
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
source /usr/local/etc/prpl-initial-startup_telegraf.config

[ ! -z ${PRPL_INIT_DEBUG_ENABLED:-} ] && set -x

if [ "${TELEGRAF_ENABLED}" == "FALSE" ] ; then
  log "Telegragf agent disabled - skipping."
  systemctl disable telegraf
  systemctl stop telegraf
  exit 0
fi

# Validate our env vars
if [ "${TELEGRAF_INFLUXDB_HTTPS_INSECURE_SKIP_VERIFY}" == "" ] ; then
  logError "ERROR : missing value for variable 'TELEGRAF_INFLUXDB_HTTPS_INSECURE_SKIP_VERIFY'"
  err
elif [ "${TELEGRAF_INFLUXDB_HTTPS_INSECURE_SKIP_VERIFY}" != "true" -a "${TELEGRAF_INFLUXDB_HTTPS_INSECURE_SKIP_VERIFY}" != "false " ] ; then
  logError "ERROR : variable 'TELEGRAF_INFLUXDB_HTTPS_INSECURE_SKIP_VERIFY' must be 'true' or 'false'."
  err
fi

log "Configure Telegraf agent"
sed --in-place --regexp-extended "s/^\s+hostname\s+=.*/  hostname = \"${AWS_EC2_INSTANCE_NAME}\"/g" /etc/telegraf/telegraf.conf

log "Configure Telegraf influxdb output plugin"
TELEGRAF_INFLUXDB_PASSWORD=$(aws secretsmanager get-secret-value --region=${AWS_REGION} --secret-id ${TELEGRAF_INFLUXDB_PASSWORD_SECRET_ID} --query SecretString --output text)
cat << EOFINBASH > /etc/telegraf/telegraf.d/outputs.influxdb.conf
# Configuration for sending metrics to InfluxDB
[[outputs.influxdb]]
urls = ["${TELEGRAF_INFLUXDB_URL}"]
database = "telegraf"
retention_policy = "${TELEGRAF_INFLUXDB_RETENTION_POLICY}"
username = "telegraf"
password = "${TELEGRAF_INFLUXDB_PASSWORD}"
insecure_skip_verify = ${TELEGRAF_INFLUXDB_HTTPS_INSECURE_SKIP_VERIFY}
EOFINBASH
unset TELEGRAF_INFLUXDB_PASSWORD

# Protect file since contains sensitive info
chmod 740 /etc/telegraf/telegraf.d/outputs.influxdb.conf

log "Start Telegraf agent"
systemctl enable telegraf
systemctl restart telegraf
