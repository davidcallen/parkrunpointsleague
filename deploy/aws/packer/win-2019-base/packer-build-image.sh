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
    echo  "    -no-ami-encryption [-ne]   : temporary disable encryption of the AMI for faster dev/debug [DEV ONLY!]"
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
ARG_AMI_ENCRYPTED="true"
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
	if [ "$1" == "-no-ami-encryption" -o "$1" == "-ne" ]; then
		ARG_AMI_ENCRYPTED="false"
		ARG_RECOGNISED=TRUE
	fi
	if [ "$1" == "-debug" ]; then
		ARG_DEBUG=-debug
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "Invalid args : Unknown argument \"${1}\"."
		err 1
	fi
	shift
done

echo "Initialise our environment for Packer..."
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

echo -e "\nValidate the Packer file..."
packer validate packer.pkr.hcl
echo

echo -e "\nBuilding Packer in account : ${PRPL_AWS_ACCOUNT_PROFILE_NAME} ..."

echo
env | grep -i PRPL_ || true
echo

echo -e "\nBuilding with Packer..."
aws-vault exec ${PRPL_AWS_VAULT_ARGS} ${PRPL_AWS_ACCOUNT_PROFILE_NAME} -- packer build ${ARG_DEBUG} -on-error=ask packer.pkr.hcl 2>&1 | tee packer.log

echo
env | grep -i PRPL_ || true
echo

ELAPSED_SECONDS=$(($SECONDS - START_TIME_SECONDS))
echo "$(date +'%Y%m%d %H:%M:%S') : Completed in $((ELAPSED_SECONDS/60)) min $((ELAPSED_SECONDS%60)) sec"

