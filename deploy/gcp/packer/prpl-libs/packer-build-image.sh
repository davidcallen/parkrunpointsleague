#!/bin/bash

PACKER_PROJECT_ID=test-249517

# -debug -on-error=ask 
packer build -on-error=ask -var "project_id=${PACKER_PROJECT_ID}" packer.json
