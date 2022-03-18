#!/bin/bash
#
# push docker image to AWS
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

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| docker-push-to-aws.sh    - Push image to AWS                         |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  " ParkRun Points League  (licensed under GPL v3)"
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  "    --image-name [-i]        - [optional] Image Name e.g. prpl-builder"
    echo  "    --tag [-t]               - [optional] Image Tag"
    echo  ""
    echo  " Examples"
    echo  "    ./docker-push-to-aws.sh --image-name prpl-builder  --tag 20190619120823"
    echo  ""
    echo  " Typically need to source env vars like : source ../../../../deploy/aws/terraform/backbone/prpl-environment.sh"
    echo  ""
    exit 1
}

ARG_PRPL_IMAGE_NAME=
ARG_PRPL_IMAGE_TAG=
ARG_RECOGNISED=FALSE
ARGS=$*
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "--help" -o  "$1" == "-h" ] ; then
		usage
	fi
	if [ "$1" == "--image-name" -o "$1" == "-i" ] ; then
		shift 1
		ARG_PRPL_IMAGE_NAME=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "$1" == "--tag" -o "$1" == "-t" ] ; then
		shift 1
		ARG_PRPL_IMAGE_TAG=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "ERROR: Invalid args : Unknown argument \"${1}\"."
		exit 1
	fi
	shift
done
# Validate Args
if [ "${ARG_PRPL_IMAGE_NAME}" == "" ] ; then
  # Default image name from current directory (if in a docker image build directory)
  if [ -f ./Dockerfile ] ; then
    ARG_PRPL_IMAGE_NAME=$(basename $PWD)
  else
    echo "ERROR : --image-name [-i] is required (if not a docker image build directory)."
    err
  fi
fi
if [ "${ARG_PRPL_IMAGE_TAG}" == "" ] ; then
  # Default image name from current directory (if in a docker image build directory)
  if [ -f ./Dockerfile -a -f ./DOCKER_IMAGE_TAG ] ; then
    ARG_PRPL_IMAGE_TAG=$(cat ./DOCKER_IMAGE_TAG)
  else
      echo "ERROR : --tag [-t] is required (if not a docker image build directory)."
    err
  fi
fi

[[ ! -v ${PRPL_DOCKER_REGISTRY} ]] && echo "ERROR : docker build environment not set. Ensure you have done 'source docker-config.sh'" && exit 1

START_DATE=`date`
echo "Push image ${ARG_PRPL_IMAGE_NAME} for tag ${ARG_PRPL_IMAGE_TAG} to AWS"
echo

# Login to AWS EKS Registry for this image
aws-vault exec ${PRPL_AWS_ACCOUNT_PROFILE_NAME} -- aws ecr get-login-password --region ${PRPL_AWS_REGION} | docker login --username AWS --password-stdin ${PRPL_AWS_ECR_DOCKER_REGISTRY}/${ARG_PRPL_IMAGE_NAME}

docker tag ${PRPL_DOCKER_REGISTRY}${ARG_PRPL_IMAGE_NAME}:${ARG_PRPL_IMAGE_TAG} ${PRPL_AWS_ECR_DOCKER_REGISTRY}/${ARG_PRPL_IMAGE_NAME}:${ARG_PRPL_IMAGE_TAG}
docker push ${PRPL_AWS_ECR_DOCKER_REGISTRY}/${ARG_PRPL_IMAGE_NAME}:${ARG_PRPL_IMAGE_TAG}

echo -e "\n----------"
echo "Finished push image ${ARG_PRPL_IMAGE_NAME} tag ${ARG_PRPL_IMAGE_TAG} to AWS at `date` (started at ${START_DATE})"
echo 
