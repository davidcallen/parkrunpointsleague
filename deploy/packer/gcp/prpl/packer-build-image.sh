#!/bin/bash

PACKER_PROJECT_ID=test-249517

packer build --debug --on-error=ask -var "project_id=${PACKER_PROJECT_ID}" packer.json
