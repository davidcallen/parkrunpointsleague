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
FILENAMES[3]=dns.tf
FILENAMES[4]=ecs-cluster.tf
FILENAMES[5]=ecs-prpl.tf
FILENAMES[6]=k8s-cluster-eks.tf
FILENAMES[7]=k8s-dashboard.tf
FILENAMES[8]=k8s-aws-alb-ingress.tf
FILENAMES[9]=k8s-efs-csi.tf
FILENAMES[10]=k8s-jenkins.tf
FILENAMES[11]=k8s-cluster-rancher.tf
FILENAMES[12]=k8s-kube2iam.tf
FILENAMES[13]=k8s-cert-manager.tf
FILENAMES[14]=teleport-bastion.tf
# Temp testing of ALB and Route53 DNS validated ACM certs
# FILENAMES[4]=application-load-balancer-public.tf
# END : Temp testing ALB

# echo ${FILENAMES[@]}

for FILENAME in "${FILENAMES[@]}" ; do
  mv ${FILENAME}${OLD_FILE_SUFFIX} ${FILENAME}${NEW_FILE_SUFFIX}
  echo "Processed file  :  ${FILENAME}"
done
cd "${START_PATH}"