#!/bin/bash
#
# Create standard testing cluster. g1-small, 3 nodes, auto-scale (1-5 nodes)

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| create-cluster-gcp.sh - Create test cluster on GCP k8s               |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  ""
    echo  " Examples"
    echo  "    ./create-cluster-gcp.sh"
    echo  ""
    exit 1
}

ARG_RECOGNISED=FALSE
ARGS=$*
while (( "$#" )); do
	ARG_RECOGNISED=FALSE

	if [ "$1" == "--help" -o  "$1" == "-h" ] ; then
		usage
	fi
	if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
		echo "ERROR: Invalid args : Unknown argument \"${1}\"."
		exit 1
	fi
	shift
done


PROJECT_ID=davidcallen

gcloud beta container clusters create "standard-cluster-1" \
	--project "${PROJECT_ID}" \
	--zone "europe-west2-a" --no-enable-basic-auth --cluster-version "1.13.6-gke.13" \
	--machine-type "g1-small" --image-type "COS" \
	--disk-type "pd-standard" --disk-size "30" \
	--metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/cloud-platform" \
	--num-nodes "3" \
	--enable-stackdriver-kubernetes \
	--enable-ip-alias \
	--network "projects/${PROJECT_ID}/global/networks/default" \
	--subnetwork "projects/${PROJECT_ID}/regions/europe-west2/subnetworks/default" \
	--default-max-pods-per-node "110" \
	--enable-autoscaling --min-nodes "1" --max-nodes "5" \
	--addons HorizontalPodAutoscaling,HttpLoadBalancing,KubernetesDashboard \
	--enable-autoupgrade \
	--enable-autorepair


# Can then get credentials with :
#
#   gcloud container clusters get-credentials standard-cluster-1 --zone europe-west2-a --project davidcallen
