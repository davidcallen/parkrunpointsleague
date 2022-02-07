set -x

export TF_VAR_org_id=957812949442
export TF_VAR_billing_account=0180B5-BE4EF8-7ED848
export TF_ADMIN=${USER}-terraform-admin-12345
# export TF_ADMIN=prpl-12347
export TF_CREDS=~/.config/gcloud/${USER}-terraform-admin.json
export TF_STATE_BUCKET=prpl-terraform-state-97239


export GOOGLE_APPLICATION_CREDENTIALS=${TF_CREDS}
export GOOGLE_PROJECT=prpl-12347

set +x
