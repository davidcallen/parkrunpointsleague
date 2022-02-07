#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail   # preserve exit code when piping e.g. with "tee"

START_PATH=${PWD}
MY_NAME=`basename $0`
START_TIME_SECONDS=$SECONDS

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| ${MY_NAME} - build packer image                                      |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "ParkRun Points League  (licensed under GPL v3)"
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  "    -debug                     : Enable debug"
    echo  "    -no-diff                   : disable diff check"
    echo  "    -no-yum_update [-ny]       : temporary disable yum update in the AMI for faster dev/debug [DEV DEBUG ONLY USAGE!]"
    echo  "    -no-ami-encryption [-ne]   : temporary disable encryption of the AMI for faster dev/debug [DEV ONLY!]"
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

ARG_DIFF_CHECK=
ARG_DEBUG=
ARG_YUM_UPDATE_ENABLED="true"
ARG_AMI_ENCRYPTED="true"
ARG_LOCAL_HV=
ARGS=$*
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "-h" ] ; then
		usage
	fi
	if [ "$1" == "-no-diff" ]; then
		shift 1
		ARG_DIFF_CHECK=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "$1" == "-no-yum-update" -o "$1" == "-ny" ]; then
		ARG_YUM_UPDATE_ENABLED="false"
		ARG_RECOGNISED=TRUE
	fi
	if [ "$1" == "-no-ami-encryption" -o "$1" == "-ne" ]; then
		ARG_AMI_ENCRYPTED="false"
		ARG_RECOGNISED=TRUE
	fi
	if [ "$1" == "-debug" ]; then
		ARG_DEBUG=-debug
		ARG_RECOGNISED=TRUE
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

echo "Initialise our environment for Packer..."
export PRPL_YUM_UPDATE_ENABLED="${ARG_YUM_UPDATE_ENABLED}"
export PRPL_AMI_ENCRYPTED=${ARG_AMI_ENCRYPTED}
source ../packer-init.sh

echo "Check our Ansible Roles are up-to-date..."
# Check for differences between the local source for ansible role and the cached role in ansible/roles (fetched from git)
# This list should match contents of requirements.yml (for non-galaxy source roles)
# diff_local_roles apache

echo -e "\nInstalled Ansible required dependancies..."
# This config needed for merge when overriding the default nested variables in role ibm-webshpere-mq
export ANSIBLE_HASH_BEHAVIOUR=merge
export ANSIBLE_FORCE_COLOR=True   # Preserve colours even when piping to "tee"
[ -f ./ansible/requirements.yml ] && ansible-galaxy install --roles-path ./ansible/roles/ -r ./ansible/requirements.yml

echo -e "\nValidate the Ansible playbook..."
ansible-playbook --syntax-check ansible/playbook.yml

echo
env | grep -i PRPL_ || true
echo

if [ "${ARG_LOCAL_HV}" == "" ] ; then
  PACKER_JSON_FILE=packer.pkr.hcl
  echo -e "\nValidate the Packer file..."
  packer validate ${PACKER_JSON_FILE}
  echo -e "\nBuilding Packer in account : ${PRPL_AWS_ACCOUNT_PROFILE_NAME} ..."
  env | grep -i AWS || true
  aws-vault exec ${PRPL_AWS_VAULT_ARGS} ${PRPL_AWS_ACCOUNT_PROFILE_NAME} -- packer build ${ARG_DEBUG} -on-error=ask ${PACKER_JSON_FILE} 2>&1 | tee packer.log
else
  # Get filename of centos-7-from-iso/ OVF file :
  export PRPL_CENTOS_VBOX_ISO_TO_OVF_FILENAMEPATH=$(ls -1 ../centos-7-from-iso/local-hypervisor/${ARG_LOCAL_HV}/output/${PRPL_AMI_PREFIX_NAME}prpl-centos-7-from-iso-*.ovf)
  if [ "${PRPL_CENTOS_VBOX_ISO_TO_OVF_FILENAMEPATH}" == "" ] ; then
    echo "ERROR : OVF source file not found. Check and run ../centos-7-from-iso packer build before this build."
    err
  fi
  # Clean temporary output files. Will be recreated by Packer from templates.
  # But create temporary placeholder files to prevent 'packer validate' from erroring
  [ -f cloud-init-floppy/user-data ] && rm -f cloud-init-floppy/user-data
  touch cloud-init-floppy/user-data
  [ -f cloud-init-floppy/meta-data ] && rm -f cloud-init-floppy/meta-data
  touch cloud-init-floppy/meta-data

  # VBox packer provisioner requires 'output' directory to not exist
  [ -d local-hypervisor/${ARG_LOCAL_HV}/output ] && rm -rf local-hypervisor/${ARG_LOCAL_HV}/output

  echo -e "\nValidate the Packer file..."
  PACKER_JSON_FILE=local-hypervisor/${ARG_LOCAL_HV}/packer.pkr.hcl
  packer validate ${PACKER_JSON_FILE}

  echo -e "\nBuilding with Packer..."
  packer build ${ARG_DEBUG} -on-error=ask ${PACKER_JSON_FILE} 2>&1 | tee packer.log
fi

echo
env | grep -i PRPL_ || true
echo

ELAPSED_SECONDS=$(($SECONDS - START_TIME_SECONDS))
echo "$(date +'%Y%m%d %H:%M:%S') : Completed in $((ELAPSED_SECONDS/60)) min $((ELAPSED_SECONDS%60)) sec"

