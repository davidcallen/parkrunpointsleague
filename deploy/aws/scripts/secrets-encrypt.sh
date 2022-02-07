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
    echo  "| ${MY_NAME} - encrypt/decrypt secrets file                            |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "ParkRun Points League  (licensed under GPL v3)"
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  "    -environment [-e]          : Environment name e.g. backbone, core, dev, demo"
    echo  "    -decrypt [-d]              : Decrypt secrets [optional]"
    echo  ""
    echo  "Run this from a terraform directory (e.g. terraform/core) using aws-vault with an 'admin' role"
    echo  "e.g."
    echo  "     aws-vault exec prpl-$(basename $(realpath .)) -- ../../scripts/secrets-encrypt.sh -e $(basename $(realpath .))"
    echo  "     aws-vault exec prpl-$(basename $(realpath .)) -- ../../scripts/secrets-encrypt.sh -e $(basename $(realpath .)) -decrypt"
    echo  ""
    exit 1
}
function err()
{
  echo  "ERROR: occured in $(basename $0)"
  cd "${START_PATH}"
  [ -f secrets.yml.encrypted.tmp ] && shred -u secrets.yml.encrypted.tmp
  exit 1
}
trap err ERR

ARG_ENVIRONMENT_NAME=
ARG_DECRYPT=FALSE
ARGS=$*
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "-h" ] ; then
		usage
	fi
	if [ "$1" == "-environment" -o "$1" == "-e" ]; then
		shift 1
		ARG_ENVIRONMENT_NAME=$1
		ARG_RECOGNISED=TRUE
	fi
	if [ "$1" == "-decrypt" -o "$1" == "-d" ]; then
		ARG_DECRYPT=TRUE
		ARG_RECOGNISED=TRUE
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "Invalid args : Unknown argument \"${1}\"."
		err 1
	fi
	shift
done

AWS_REGION=eu-west-1
if [ "${ARG_DECRYPT}" == "TRUE" ] ; then
  if [ ! -f secrets.yml.encrypted ] ; then
    echo "ERROR : could not find 'secrets.yml.encrypted'"
    err
  fi
  # Decode encrypted file from base64 into a temporary binary file ready for decryption
  base64 --decode secrets.yml.encrypted > secrets.yml.encrypted.tmp

  # Note with the decryption when using a SYMMETRIC key we do not need to specify the key-id (or alias)
  # since this is contained within the encrypted data.
  #    --key-id alias/prpl-${ARG_ENVIRONMENT_NAME}-kms-secrets \
  aws kms decrypt \
    --region ${AWS_REGION} \
    --ciphertext-blob fileb://secrets.yml.encrypted.tmp \
    --output text \
    --query Plaintext | base64 --decode > secrets.yml
  echo "Finished decrypt of 'secrets.yml.encrypted' ==>> 'secrets.yml'."
  [ -f secrets.yml.encrypted.tmp ] && shred -u secrets.yml.encrypted.tmp
else
  if [ ! -f secrets.yml ] ; then
    echo "ERROR : could not find 'secrets.yml'"
    err
  fi
  aws kms encrypt \
    --key-id alias/prpl-${ARG_ENVIRONMENT_NAME}-kms-secrets \
    --region ${AWS_REGION} \
    --plaintext fileb://secrets.yml \
    --output text \
    --query CiphertextBlob \
    > secrets.yml.encrypted
  # Note that the encrypted output is in base64 format
  echo "Finished encrypt of 'secrets.yml' ==>> 'secrets.yml.encrypted'."
fi

