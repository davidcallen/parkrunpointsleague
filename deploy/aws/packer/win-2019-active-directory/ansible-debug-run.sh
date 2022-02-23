#!/bin/bash
# Pass "-v" for verbose ansible logging
set -o errexit
set -o pipefail   # preserve exit code when piping e.g. with "tee"

source ../packer-init.sh

# This config needed for merge when overriding the default nested variables in role ibm-webshpere-mq
export ANSIBLE_HASH_BEHAVIOUR=merge

env | grep -i aws || true
env | grep TA_CLOUD || true
echo

# Installed required dependancies
ansible-galaxy install --roles-path ./ansible/roles/ -r ./ansible/requirements.yml
echo

ansible-playbook --syntax-check ansible/playbook.yml
echo

# NOTE : check that the correct target IP address (packer build instance) is in file : ansible/group_vars/static
export ANSIBLE_FORCE_COLOR=True   # Preserve colours even when piping to "tee"
ansible-playbook ansible/playbook.yml \
  -i ansible/group_vars/static \
  -e TA_CLOUD_CUSTOMER=${TA_CLOUD_CUSTOMER} \
  -e TA_CLOUD_PACKER_FILES_AWS_ACCOUNT_ID=${TA_CLOUD_PACKER_FILES_AWS_ACCOUNT_ID} \
  -e AMI_NAME=ta-$(basename ${PWD})-`date +%Y-%m-%d-%H%M%S`-${GIT_COMMIT_ID} \
  --private-key=~/.ssh/aws-ec2/${TA_CLOUD_CUSTOMER}-${TA_CLOUD_ENVIRONMENT}-ssh-key-packer-builder.pem $* 2>&1 | tee ansible.log
