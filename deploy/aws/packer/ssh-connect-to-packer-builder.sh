#!/bin/bash
# For easy SSH connection to a running packer build vm, for debugging purposes
set -o errexit
set -o nounset
set -o pipefail   # preserve exit code when piping e.g. with "tee"

START_PATH=${PWD}
MY_NAME=`basename $0`
START_TIME_SECONDS=$SECONDS

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| ${MY_NAME} - ssh connect to packer builder vm for debugging          |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "ParkRun Points League  (licensed under GPL v3)"
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  "    -local-hv [-l]             : option to run locally against named hypervisor e.g. 'vbox' for faster development"
    echo  ""
    exit 1
}
function err()
{
  echo  "ERROR: occured in $(basename $0)"
  cd "${START_PATH}"
  exit 1
}
trap err ERR

ARG_LOCAL_HV=
ARGS=$*
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "-h" ] ; then
		usage
	fi
	if [ "$1" == "-local-hv" ]; then
	  shift 1
		ARG_LOCAL_HV=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "Invalid args : Unknown argument \"${1}\"."
		err 1
	fi
	shift
done

if [ "${ARG_LOCAL_HV}" == "" ] ; then
  ANSIBLE_TARGET_IP_FILE_NAMEPATH=ansible/group_vars/static
  if [ ! -f ${ANSIBLE_TARGET_IP_FILE_NAMEPATH} ] ; then
    echo "ERROR : file '${ANSIBLE_TARGET_IP_FILE_NAMEPATH}' does not exist. Was ansible run ok?"
    exit 1
  fi
  SSH_USER_AND_IP=$(cat ${ANSIBLE_TARGET_IP_FILE_NAMEPATH} | grep '@')
  if [ "${SSH_USER_AND_IP}" == "" ] ; then
    echo "ERROR : could not get ansible target IP from ${ANSIBLE_TARGET_IP_FILE_NAMEPATH}. Was ansible run ok?"
    exit 1
  fi
  echo "Connecting to ansible target ${SSH_USER_AND_IP} ..."
  ssh -i ~/.ssh/prpl-aws/prpl-core-ssh-key-packer-builder ${SSH_USER_AND_IP}

elif [ "${ARG_LOCAL_HV}" == "vbox" ] ; then

  # Get the random ssh port assigned to our VirtualBox packer vm
  GET_SSH_PORT_LINE=$(cat packer.log | grep 'Creating forwarded port mapping for communicator (SSH, WinRM, etc) (host port ')
  GET_SSH_PORT=`echo "${GET_SSH_PORT_LINE}" | cut -d ')' -f 2 | cut -d ' ' -f 4`

  echo "Connecting to ansible target ${SSH_USER_AND_IP} on port ${GET_SSH_PORT} ..."
  ssh -i ~/.ssh/my-ssh-key-packer-builder centos@127.0.0.1 -p ${GET_SSH_PORT}
fi
