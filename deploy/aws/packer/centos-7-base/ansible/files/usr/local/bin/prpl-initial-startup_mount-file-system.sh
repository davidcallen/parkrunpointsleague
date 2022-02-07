#!/bin/bash
# Initial-startup of EC2 instance scripts.  Mount the persistent filesystem (EBS or EFS)
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
source /usr/local/etc/prpl-initial-startup_mount-file-system.config

[ ! -z ${PRPL_INIT_DEBUG_ENABLED:-} ] && set -x

#  Validate our env vars
if [ "${FILE_SYSTEM_MOUNT_POINT}" == "" -o "${FILE_SYSTEM_MOUNT_TARGET}" == "" ] ; then
  log "No 2nd mount point configured - skipping mount of persistent file system."
  exit 0
fi

function backup_app_contents() {
  [ ! -d ${FILE_SYSTEM_MOUNT_TARGET}_old ] && mv ${FILE_SYSTEM_MOUNT_TARGET} ${FILE_SYSTEM_MOUNT_TARGET}_old
}

function reinstate_app_contents() {
  # Get count of files in mount point to see if it is a fresh one
  FILES_COUNT_IN_MOUNT_POINT=$(ls -1 ${FILE_SYSTEM_MOUNT_POINT} | wc -l)

  # If mount point is a fresh (empty) one then copy across any files from the AMI "baked-in" target location
  if [ ${FILES_COUNT_IN_MOUNT_POINT} -le 1 ] ; then
    log "Moving back-up of original app directory onto fresh mount point ${FILE_SYSTEM_MOUNT_POINT}"

    # Use ls with 1 item per line and ignore the "." and ".." items
    for FILE in `ls -A1 ${FILE_SYSTEM_MOUNT_TARGET}_old/` ; do
        log "Moving file '${FILE}' onto fresh mount point ${FILE_SYSTEM_MOUNT_POINT}"
        mv ${FILE_SYSTEM_MOUNT_TARGET}_old/${FILE} ${FILE_SYSTEM_MOUNT_POINT}/
    done
  fi
}

AWS_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

if [ "${FILE_SYSTEM_AWS_EFS_ID}" != "" ] ; then
  log "Checking if need to mount EFS file system on ${FILE_SYSTEM_MOUNT_POINT}"

  # Configure fstab to mount the EFS file system as boot time
  GREP_FSTAB=$(cat /etc/fstab | grep "${AWS_ZONE}\.${FILE_SYSTEM_AWS_EFS_ID}" || true)
  if [ "${GREP_FSTAB}" == "" ] ; then
    log "Adding App EFS file system to /etc/fstab"
    echo "${AWS_ZONE}.${FILE_SYSTEM_AWS_EFS_ID}.efs.${AWS_REGION}.amazonaws.com:/ ${FILE_SYSTEM_MOUNT_POINT} nfs4 defaults 0 2" >> /etc/fstab
  fi

  # Check if ASG has only 1 EC2 instance attached to it.
  # More than one could mean that the EFS is locked by the older instance.  Reattempts for up to 5 mins.
  if [ "${AWS_ASG_NAME}" != "" ] ; then
    CHECK_EFS_ATTEMPTS=1
    CHECK_EFS_OK=FALSE
    while [ ${CHECK_EFS_ATTEMPTS} -lt ${CHECK_EFS_ASG_MAX_ATTEMPTS} ] ; do
      log "Check if EFS currently in use by another instance [${CHECK_EFS_ATTEMPTS}]"
      ASG_EC2_INSTANCES=$(aws autoscaling describe-auto-scaling-groups --region=${AWS_REGION} --auto-scaling-group-name ${AWS_ASG_NAME} | jq ' [ .AutoScalingGroups[].Instances[] ] | length')
      if [ ${ASG_EC2_INSTANCES} -le 1 ] ; then
        log "Check if EFS currently in use by another instance [OK]"
        CHECK_EFS_OK=TRUE
        break
      fi
      CHECK_EFS_ATTEMPTS=$(( ${CHECK_EFS_ATTEMPTS} + 1 ))
      sleep 10
    done
    if [ "${CHECK_EFS_OK}" == "FALSE" ] ; then
      logError "Check if EFS currently in use by another instance [ERROR] - EFS wait timed-out - still in use by too many instances !!!"
      exit 1
    fi
  fi

elif [ "${FILE_SYSTEM_AWS_EBS_DEVICE_NAME}" != "" ]; then
  log "Checking if need to mount EBS file system on ${FILE_SYSTEM_MOUNT_POINT}"

  GREP_FSTAB=$(cat /etc/fstab | grep "\${FILE_SYSTEM_MOUNT_POINT}" || true)
  if [ "${GREP_FSTAB}" == "" ] ; then
    log "Adding App EBS file system to /etc/fstab"
    echo -e "${FILE_SYSTEM_AWS_EBS_DEVICE_NAME} ${FILE_SYSTEM_MOUNT_POINT} ext4 defaults 0 0\n" >> /etc/fstab

    FILE_SYSTEM=`lsblk -no FSTYPE ${FILE_SYSTEM_AWS_EBS_DEVICE_NAME}`
    if [ $? -eq 0 ] ; then
      if [ `echo ${FILE_SYSTEM} | wc -w` -ne 1 ] ; then
        log "Formating EBS disk with an EXT4 file system"
        mkfs -t ext4 ${FILE_SYSTEM_AWS_EBS_DEVICE_NAME}
      fi
    fi
  fi
fi

if [ ! -d ${FILE_SYSTEM_MOUNT_POINT} ] ; then
  mkdir ${FILE_SYSTEM_MOUNT_POINT}
  chown ${FILE_SYSTEM_MOUNT_OWNER_USER}:${FILE_SYSTEM_MOUNT_OWNER_GROUP} ${FILE_SYSTEM_MOUNT_POINT}
fi
backup_app_contents
log "Mounting the 2nd file system"
mount ${FILE_SYSTEM_MOUNT_POINT}
chown ${FILE_SYSTEM_MOUNT_OWNER_USER}:${FILE_SYSTEM_MOUNT_OWNER_GROUP} ${FILE_SYSTEM_MOUNT_POINT}
reinstate_app_contents
log "Symlinking mount point ${FILE_SYSTEM_MOUNT_POINT} -> ${FILE_SYSTEM_MOUNT_TARGET}"
ln -s ${FILE_SYSTEM_MOUNT_POINT} ${FILE_SYSTEM_MOUNT_TARGET}
log "Mounting the 2nd file system : finished"
