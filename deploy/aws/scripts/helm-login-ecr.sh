#!/bin/bash
#
# Do a Helm login for AWS ECR
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

[[ ! -v PRPL_AWS_ECR_DOCKER_REGISTRY ]] && echo "ERROR : AWS environment not set. Ensure you have done 'source prpl-environment.sh'" && exit 1

# Login to AWS EKS Registry for this image
export HELM_EXPERIMENTAL_OCI=1

aws-vault exec ${PRPL_AWS_ACCOUNT_PROFILE_NAME} -- aws ecr get-login-password \
  --region ${PRPL_AWS_REGION} | helm registry login \
  --username AWS \
  --password-stdin ${PRPL_AWS_ECR_DOCKER_REGISTRY}

echo "Finished : Helm is now logged into your ECR."