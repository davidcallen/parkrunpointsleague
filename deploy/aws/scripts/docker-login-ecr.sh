#!/bin/bash
#
# Do a docker login for AWS ECR
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

[[ ! -v ${PRPL_DOCKER_REGISTRY} ]] && echo "ERROR : docker build environment not set. Ensure you have done 'source docker-config.sh'" && exit 1

# Login to AWS EKS Registry for this image
aws-vault exec ${PRPL_AWS_ACCOUNT_PROFILE_NAME} -- aws ecr get-login-password --region ${PRPL_AWS_REGION} | docker login --username AWS --password-stdin ${PRPL_AWS_ECR_DOCKER_REGISTRY}/${ARG_PRPL_IMAGE_NAME}
