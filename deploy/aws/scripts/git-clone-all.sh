#!/bin/bash
#
# Checkout (clone) all our git repos in standard folder layout, to make a cloud development folder that can be opened in Intellij.
#
# ParkRun Points League  (licensed under GPL v3)
#
# The standard folder layout will be compatible with helper scripts
#
set -o errexit
set -o nounset
START_PATH=${PWD}
function err()
{
  echo  "ERROR in $0"
  cd ${START_PATH}
  exit 1
}
trap err ERR

# Adjust GIT_CHECKOUT_PATH to suit your destination path
GIT_CHECKOUT_PATH=$PWD/../
if [ $# -gt 0 ] ; then
  GIT_CHECKOUT_PATH=$1
fi

cd ${GIT_CHECKOUT_PATH}
[ ! -d prpl ] && git clone git@github.com:davidcallen/parkrunpointsleague.git

# ------------------------    ansible-roles   ------------------------------------------
cd ${GIT_CHECKOUT_PATH}
[ ! -d ansible-roles ] && mkdir -p ansible-roles
cd ansible-roles
function ansible_roles_git_clone() {
  ARG_REPO_NAME=$1
  [ ! -d ${ARG_REPO_NAME} ] && git clone git@github.com:davidcallen/${ARG_REPO_NAME}.git
  return 0
}
ansible_roles_git_clone ansible-role-amazon-cloudwatch-agent
ansible_roles_git_clone ansible-role-awscli
ansible_roles_git_clone telegraf


# ------------------------  terraform-modules ------------------------------------------
cd ${GIT_CHECKOUT_PATH}
[ ! -d terraform-modules ] && mkdir terraform-modules
cd terraform-modules
function terraform_modules_git_clone() {
  ARG_REPO_NAME=$1
  [ ! -d ${ARG_REPO_NAME} ] && git clone git@github.com:davidcallen/${ARG_REPO_NAME}.git
  return 0
}
terraform_modules_git_clone terraform-module-aws-asm-secret
terraform_modules_git_clone terraform-module-aws-jenkins-controller
terraform_modules_git_clone terraform-module-aws-nexus
terraform_modules_git_clone terraform-module-aws-vpc-flow-logs-s3
terraform_modules_git_clone terraform-module-iam-jenkins
terraform_modules_git_clone terraform-module-iam-nexus
terraform_modules_git_clone terraform-module-iam-packer-build
terraform_modules_git_clone terraform-module-iam-s3-bucket-policy-for-users
terraform_modules_git_clone terraform-module-route53-resolver-rules-sharing-cross-accounts
terraform_modules_git_clone terraform-module-sns-topic-subs
terraform_modules_git_clone terraform-module-tgw-sharing-cross-accounts


cd ${START_PATH}
echo "Finished cloning repositories : OK"