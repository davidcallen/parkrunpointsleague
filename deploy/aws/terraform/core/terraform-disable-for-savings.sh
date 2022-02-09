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

# # process any child modules first
# [ -f ./packer/terraform-disable-files-for-savings.sh ] && cd ./packer && ./terraform-disable-files-for-savings.sh ${ENABLE_FILES}

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

if [ "${ENABLE_OR_DISABLE}" == "ENABLE" ] ; then
  sed -i 's/vpc_id.*=.*"DISABLED" # module.vpc.vpc_id.*/vpc_id = module.vpc.vpc_id/g' packer.tf
else
  sed -i 's/vpc_id\s.*=\s.*module.vpc.vpc_id/vpc_id = "DISABLED" # module.vpc.vpc_id     # DISABLED HACK/g' packer.tf
fi

# Define your files for enable/disabling (via renaming)
FILENAMES[0]=vpc.tf
FILENAMES[1]=packer/security-groups.tf
FILENAMES[2]=jenkins.tf
FILENAMES[3]=nexus.tf
FILENAMES[4]=secrets.tf
FILENAMES[5]=bootstrap/kms.tf

# echo ${FILENAMES[@]}

for FILENAME in "${FILENAMES[@]}" ; do
  mv ${FILENAME}${OLD_FILE_SUFFIX} ${FILENAME}${NEW_FILE_SUFFIX}
  echo "Processed file  :  ${FILENAME}"
done
cd "${START_PATH}"