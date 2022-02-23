# Set environment variables for configuring Packer (and possibly other tools) to work with this aws account
#
#  source this script into your shell prior to running Packer build script e.g.
#
#    $ cd cloud/packer/foobar/
#    $ source ../../terraform/sandpit-01/prpl-environment.sh
#    $ ./packer-build-image.sh
#
export PRPL_ENVIRONMENT=core
export PRPL_AWS_ACCOUNT_PROFILE_NAME=prpl-core

# Either unset PRPL_AMI_PREFIX_NAME and will then default automatically
unset PRPL_AMI_PREFIX_NAME
#   ... or override it to blank
# export PRPL_AMI_PREFIX_NAME=
