#!/bin/bash

set -x

gsutil mb -p ${TF_ADMIN} gs://${TF_STATE_BUCKET}

# Untested : Need "compute.image.user" role in our project
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/compute.image.user
  
set +x
