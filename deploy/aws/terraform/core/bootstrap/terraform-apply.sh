#!/bin/bash
# Run this from the intended terraform directory  !!

# Uses the tf variables from parent directory
terraform-v1.0.11 apply -var-file=../terraform.tfvars
