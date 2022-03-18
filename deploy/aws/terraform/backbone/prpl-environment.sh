# Set environment variables for configuring Packer (and possibly other tools) to work with this aws account
#
#  source this script into your shell prior to running Packer build script e.g.
#
#    $ cd cloud/packer/foobar/
#    $ source ../../terraform/sandpit-01/prpl-environment.sh
#    $ ./packer-build-image.sh
#
export PRPL_ENVIRONMENT=backbone
export PRPL_AWS_ACCOUNT_PROFILE_NAME=prpl-backbone
export PRPL_AWS_REGION=eu-west-1
export PRPL_AWS_ACCOUNT_ID=597767386394
export PRPL_AWS_ECR_DOCKER_REGISTRY=${PRPL_AWS_ACCOUNT_ID}.dkr.ecr.${PRPL_AWS_REGION}.amazonaws.com/parkrunpointsleague.org

# Either unset PRPL_AMI_PREFIX_NAME and will then default automatically
unset PRPL_AMI_PREFIX_NAME
#   ... or override it to blank
# export PRPL_AMI_PREFIX_NAME=
