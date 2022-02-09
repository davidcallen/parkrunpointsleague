# Terraform for provisioning PRPL Environments

## Environments

Environments and significant resources : 

- Backbone (root/master) account
    - VPC
    - Transit Gateway
- Core account
    - VPC
    - AMI Building
    
    
## Running the terraform

There is a Catch-22 on running the 1st terraform in an account and having the IAM permissions to do so.

One method for this follows ...

Notes:
- I use the [aws-vault](https://github.com/99designs/aws-vault) tool to avoid saving AWS Access Keys in plaintext in ~/.aws directory.
```editorconfig
# Example ~/.aws/config and assumes usage of aws-vault ...
# 
# backbone is currently using the same account as core.  May change in future.
[profile prpl]

# Only Use root for first apply of terraform on backbone/bootstrap - will create Admin group and attach it to david user
[profile prpl-root]
mfa_serial=arn:aws:iam::999999999999:mfa/davidallen

[profile prpl-backbone]
mfa_serial=arn:aws:iam::999999999999:mfa/david

[profile prpl-core-first-bootstrap]
mfa_serial=arn:aws:iam::597767386394:mfa/david
source_profile=prpl-backbone
# On first run of terraform in core/bootstrap then need to use OrganizationAccountAccessRole
role_arn = arn:aws:iam::228947135432:role/OrganizationAccountAccessRole

[profile prpl-core]
mfa_serial=arn:aws:iam::999999999999:mfa/david
source_profile=prpl-backbone
role_arn = arn:aws:iam::88888888888:role/prpl-core-admin
```

- I use a ```bootstrap``` directory in each environment to provide essentials like s3 terraform-state bucket and Admin IAM permission.

### Running the terraform : in Backbone
In directory ```backbone/bootstrap``` do 1st terraform run using **root management user credentials** 

    ```shell script
    aws-vault exec prpl-root -- terraform init
    # and then ...
    aws-vault exec prpl-root -- ./terraform-apply.sh    
    ```

- then subsequent terraform runs as your personal IAM Admin user (e.g. david) by using aws-vault profile ```prpl-backbone``` 

    ```shell script
    aws-vault exec prpl-backbone -- ./terraform-apply.sh    
    ```

- and in ```backbone``` directory do terraform runs as your personal IAM Admin user (e.g. david) by using aws-vault profile ```prpl-backbone```  

    ```shell script
    aws-vault exec prpl-backbone -- terraform init
    aws-vault exec prpl-backbone -- terraform apply    
    ```

### Running the terraform : in Core (and others)
In directory ```core/bootstrap``` do 1st terraform run using aws-vault profile ```prpl-core-first-bootstrap``` (is configured to use role_arn of ```OrganizationAccountAccessRole```) 

    ```shell script
    aws-vault exec prpl-core-first-bootstrap -- terraform init
    # and then ...
    aws-vault exec prpl-core-first-bootstrap -- ./terraform-apply.sh    
    ```

- then subsequent terraform runs as your personal IAM Admin user (e.g. david) by using aws-vault profile ```prpl-core``` 

    ```shell script
    aws-vault exec prpl-core -- ./terraform-apply.sh    
    ```


- in ```core``` directory create the secrets file using SOPS as your personal IAM Admin user (e.g. david) by using aws-vault profile ```prpl-core```  

    ```shell script
    # Use the "kms_secrets_arn" output from above core/bootstrap apply for below SOPS_KMS_ARN env var. 
    SOPS_KMS_ARN="arn:aws:kms:eu-west-1:123456789:key/xxxxxxxxx-yyyyy-zzzzzz-xxxxx-xxxxxxxx" aws-vault exec prpl-$(basename $(realpath .)) -- sops secrets.encrypted.json
    ```
  
- and in ```core``` directory do terraform runs as your personal IAM Admin user (e.g. david) by using aws-vault profile ```prpl-core```  

    ```shell script
    aws-vault exec prpl-core -- terraform init
    aws-vault exec prpl-core -- terraform apply    
    ```
  
- a convenient generic aws-vault+terraform command line is :

    ```shell script
    # The below uses ```basename``` to get the aws profile name from the current directory : 
    aws-vault --debug exec prpl-$(basename $(realpath .)) -- terraform-v1.0.11 apply
    ```


## Formatting files
- Use IntelliJ for terraform development.
- Install the Terraform plugin in Intellij
- Use Terraform formatter from Intellij to auto-format terraform files. 
