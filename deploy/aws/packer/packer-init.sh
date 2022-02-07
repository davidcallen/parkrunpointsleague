# Initialise environment for Packer building.  This script is "source-d" from each individual packer-build-image.sh script.
#
export PRPL_ORG_SHORT_NAME=prpl

if [ -z ${PRPL_ENVIRONMENT:-} ] ; then
  echo "ERROR: env var is 'PRPL_ENVIRONMENT' is not set. Ensure you have bash 'source-d' the approriate prpl-environment.sh"
  exit 1
fi

if [ -z ${PRPL_AWS_ACCOUNT_PROFILE_NAME:-} ] ; then
  export PRPL_AWS_ACCOUNT_PROFILE_NAME=${PRPL_ORG_SHORT_NAME}-${PRPL_ENVIRONMENT}
fi

export PRPL_GIT_COMMIT_ID=$(git rev-parse --short HEAD)

# Set our AMI Prefix Name to the git branch name (blank if master/main)
export GIT_BRANCH_NAME=$(git branch --show-current)
if [ "${GIT_BRANCH_NAME}" == "master" -o "${GIT_BRANCH_NAME}" == "main" ] ; then
  GIT_BRANCH_NAME=
  PRPL_AMI_PREFIX_NAME=
else
  # Check if PRPL_AMI_PREFIX_NAME is NOT defined - then use git branch name
  if [[ ! -v PRPL_AMI_PREFIX_NAME ]] ; then
    PRPL_AMI_PREFIX_NAME="${GIT_BRANCH_NAME}-"
  fi
fi
export PRPL_AMI_PREFIX_NAME

# Set our AMI Suffix Name based on if building encrypted AMI (once encrypted AMI used everywhere then reverse this)
PRPL_AMI_SUFFIX_NAME=
if [ "${PRPL_AMI_ENCRYPTED}" != "false" ] ; then
  PRPL_AMI_SUFFIX_NAME="-enc"
fi
export PRPL_AMI_SUFFIX_NAME

# Set our AMI KMS Key ID based on if building encrypted AMI (must be blank in packer.json if not-encrypting)
PRPL_AMI_ENCRYPTED_KMS_KEY_ID=
if [ "${PRPL_AMI_ENCRYPTED}" == "true" ] ; then
  PRPL_AMI_ENCRYPTED_KMS_KEY_ID="alias/${PRPL_ORG_SHORT_NAME}-${PRPL_ENVIRONMENT}-kms-ami"
fi
export PRPL_AMI_ENCRYPTED_KMS_KEY_ID

PRPL_AWS_VAULT_ARGS=
if [ -z ${PRPL_MFA_USE_YUBIKEY:-} ] ; then
  PRPL_MFA_USE_YUBIKEY=FALSE
fi
if [ "${PRPL_MFA_USE_YUBIKEY}" == "TRUE" ] ; then
  # Check if Yubikey manager (for keyless MFA) is installed
  CHECK_YUBIKEY_MANAGER_INSTALLED=$(which ykman > /dev/null)
  if [ $? -ne 0 ] ; then
    echo "ERROR : Yubikey for MFA configured but ykman not found"
    exit 1
  fi
  PRPL_AWS_VAULT_ARGS="${PRPL_AWS_VAULT_ARGS}--prompt ykman "
fi
export PRPL_AWS_VAULT_ARGS

echo -e "\nPacker version : $(packer --version)\n"

# ----------------------------------------------------------------------------------------------------------------------
# Check for differences between the local source for ansible role and the cached role in ansible/roles (fetched from git)
# ----------------------------------------------------------------------------------------------------------------------
function diff_local_roles() {
    ARG_ROLE_NAME=$1
    local LOCAL_SOURCE_PATH=../../../ansible-roles
    if [ ! -d ${LOCAL_SOURCE_PATH}/${ARG_ROLE_NAME} ] ; then
        LOCAL_SOURCE_PATH=../../../ansible-roles/external-roles
    fi
    if [ -d ${LOCAL_SOURCE_PATH}/${ARG_ROLE_NAME} -a -d ansible/roles/${ARG_ROLE_NAME} ] ; then
      echo "Diff checking ${LOCAL_SOURCE_PATH}/${ARG_ROLE_NAME} against ansible/roles/${ARG_ROLE_NAME}"
      diff -r --exclude=.git --exclude=.galaxy_install_info ${LOCAL_SOURCE_PATH}/${ARG_ROLE_NAME} ansible/roles/${ARG_ROLE_NAME}
      if [ $? -ne 0 ] ; then
          echo
          echo "WARNING : differences exist between ansible/roles/${ARG_ROLE_NAME} and your local copy in ${LOCAL_SOURCE_PATH}/${ARG_ROLE_NAME}"
          echo
          read -p "Press any key to continue or CTRL+C to quit"
      fi
    fi
}
