#!/bin/bash
#
# Common settings for build and publish docker images
set -o errexit
set -o nounset

# GCP
# export PRPL_DOCKER_REGISTRY=eu.gcr.io/davidcallen/
# Local-only e.g. for minikube
export PRPL_DOCKER_REGISTRY=
export PRPL_DOCKER_REGISTRY=
export PRPL_DOCKER_REGISTRY_GCP=eu.gcr.io/davidcallen/

echo "Using Docker Registry ${PRPL_DOCKER_REGISTRY}"
echo
