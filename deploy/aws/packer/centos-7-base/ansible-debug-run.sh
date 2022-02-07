#!/bin/bash
# For re-running a failed ansible playbook whilst Packer VM still alive.
#
# Pass "-v" for verbose ansible logging
set -o errexit
set -o pipefail   # preserve exit code when piping e.g. with "tee"

echo "Initialise our environment for Packer..."
source ../packer-init.sh

# This config needed for merge when overriding the default nested variables in role ibm-webshpere-mq
export ANSIBLE_HASH_BEHAVIOUR=merge

env | grep -i aws || true
env | grep -i prpl_ || true
echo

# Installed required dependancies
[ -f ./ansible/requirements.yml ] && ansible-galaxy install --roles-path ./ansible/roles/ -r ./ansible/requirements.yml
echo

ansible-playbook --syntax-check ansible/playbook.yml
echo

# NOTE : check that the correct target IP address (packer build instance) is in file : ansible/group_vars/static
export ANSIBLE_FORCE_COLOR=True   # Preserve colours even when piping to "tee"
ansible-playbook ansible/playbook.yml \
  -i ansible/group_vars/static \
  -e PRPL_ORG_SHORT_NAME=${PRPL_ORG_SHORT_NAME} \
  -e AMI_NAME=prpl-$(basename ${PWD})-`date +%Y-%m-%d-%H%M%S`-${GIT_COMMIT_ID} \
  --private-key=~/.ssh/${PRPL_ORG_SHORT_NAME}-aws/${PRPL_ORG_SHORT_NAME}-${PRPL_ENVIRONMENT}-ssh-key-packer-builder $* 2>&1 | tee ansible.log
