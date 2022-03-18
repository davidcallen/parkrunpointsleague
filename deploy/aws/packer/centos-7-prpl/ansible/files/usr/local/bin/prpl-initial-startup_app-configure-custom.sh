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
source /usr/local/etc/prpl-initial-startup_mount-file-system.config

[ ! -z ${PRPL_INIT_DEBUG_ENABLED:-} ] && set -x

# Validate our env vars

# ... override this custom configure script if needed in app-specific AMI (based from this AMI)
if [ ! -f ${FILE_SYSTEM_MOUNT_TARGET}/prpld.xml ] ; then
  cat > ${FILE_SYSTEM_MOUNT_TARGET}/prpld.xml << EOF
<config>
	<http>
		<port>8080</port>
	</http>

	<database>
		<host>localhost</host>
		<name>PRPL</name>
		<port>3306</port>
		<password>parklife</password>
	</database>

	<logging>
		<level>information</level>
		<debug-html>false</debug-html>
		<trace-html>false</trace-html>
		<show-hostname>true</show-hostname>
	</logging>

	<results>
		<scraping-enabled>true</scraping-enabled>
		<data-path>../data/results/</data-path>
		<sleep-between-runs-seconds>360</sleep-between-runs-seconds>
		<non-parkrun-day-slow-down-factor>4</non-parkrun-day-slow-down-factor>

		<recreate-all-results>false</recreate-all-results>
		<use-history-cache>false</use-history-cache>
		<recreate-all-leagues>false</recreate-all-leagues>
	</results>

</config>
EOF
else

fi