#!/bin/bash
#
# Perform a "git pull" on all our git repos in our standard folder layout (as created by git-clone-all.sh)
#
# ParkRun Points League  (licensed under GPL v3)
#
# The standard folder layout will be compatible with helper scripts
#
set -o errexit
set -o nounset

START_PATH=${PWD}
MY_NAME=`basename $0`

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| ${MY_NAME} - git pull in all git subdirectories                      |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "ParkRun Points League  (licensed under GPL v3)"
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  "    -path              - path to check for git pull in all git subdirectories"
    echo  ""
    exit 1
}
function err()
{
  echo  "ERROR in $0"
  cd ${START_PATH}
  exit 1
}
trap err ERR


ARG_CHECK_PATH=
ARGS=$*
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "-h" ] ; then
		usage
	fi
	if [ "$1" == "-path" ]; then
		shift 1
		ARG_CHECK_PATH=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "Invalid args : Unknown argument \"${1}\"."
		err 1
	fi
	shift
done

EXPECTED_DIR_NAME=prpl

# Check am in the "prpl" directory
CHECK_DIR=`basename $PWD`
if [ "${CHECK_DIR}" != "${EXPECTED_DIR_NAME}" ] ; then
  echo "ERROR : not in ${EXPECTED_DIR_NAME} directory"
  exit 1
fi


echo "================= ${EXPECTED_DIR_NAME} =================="
git pull
echo

# ------------------------------------------  Terraform Modules  -------------------------------------------------------
TERRAFORM_MODULES_PATH=../terraform-modules
cd ${TERRAFORM_MODULES_PATH}
for DIR in `ls -1 .` ; do
  if [ ! -d ${DIR} -o ! -d ${DIR}/.git ] ; then
    continue
  fi
  echo "================= ${TERRAFORM_MODULES_PATH}/$DIR =================="
  cd $DIR && git pull && echo && cd ..
  echo
done

# --------------------------------------------  Ansible Roles  --------------------------------------------------------
cd ${START_PATH}
ANSIBLE_ROLES_PATH=../ansible-roles
cd ${ANSIBLE_ROLES_PATH}
for DIR in `ls -1 .` ; do
  if [ "${DIR}" == "external-roles" ] ; then
    continue
  fi
  if [ ! -d ${DIR} -o ! -d ${DIR}/.git ] ; then
    continue
  fi
  echo "================= ${ANSIBLE_ROLES_PATH}/$DIR =================="
  cd $DIR && git pull && echo && cd ..
  echo
done

cd ${START_PATH}