#!/bin/bash
# Simple way of disabling aws resources on a per-file basis to save on costs when not in use.
#
# Renames files so terraform does not see them.
#
# Note: Move to using new "enabled" terraform attribute when Issue https://github.com/hashicorp/terraform/issues/21953 is completed.
#
set -o nounset
set -o errexit
# set -x
START_PATH=$PWD
function err()
{
  echo  "ERROR occured in $0 !!!"
  cd "${START_PATH}"
  exit 1
}
trap err ERR
ENABLE_OR_DISABLE=$1

# process any child modules first
[ -f ./packer/terraform-disable-files-for-savings.sh ] && cd ./packer && ./terraform-disable-files-for-savings.sh ${ENABLE_FILES}

cd "${START_PATH}"
if [ "${ENABLE_OR_DISABLE}" == "ENABLE" ] ; then
  OLD_FILE_SUFFIX="-DISABLED"
  NEW_FILE_SUFFIX=""
elif [ "${ENABLE_OR_DISABLE}" == "DISABLE" ] ; then
  NEW_FILE_SUFFIX="-DISABLED"
  OLD_FILE_SUFFIX=""
else
  echo "ERROR : argument needed [ENABLE or DISABLE]."
  exit 1
fi

# Define your files for enable/disabling (via renaming)
FILENAMES[0]=tgw.tf
FILENAMES[1]=vpc.tf
FILENAMES[2]=client-vpn.tf
FILENAMES[3]=route53.tf
FILENAMES[4]=ec2-test.tf
FILENAMES[5]=ec2-test-02.tf

# echo ${FILENAMES[@]}

for FILENAME in "${FILENAMES[@]}" ; do
  mv ${FILENAME}${OLD_FILE_SUFFIX} ${FILENAME}${NEW_FILE_SUFFIX}
  echo "Processed file  :  ${FILENAME}"
done
cd "${START_PATH}"