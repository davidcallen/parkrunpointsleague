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

# Using 
#  --preemptible 						VMs for 80% discount but a) live for 24hrs max, b) may be spun down if google needs space.
#  --machine-type "n1-standard-1"		Need at least this otherwise thoings wont work and loose lots of time troubleshooting
#  --enable-autoscaling					Scaling - lets dot it!
gcloud beta container --project "${PROJECT_ID}" clusters create "standard-cluster-1" \
	--zone "europe-west2-a" --no-enable-basic-auth --cluster-version "1.13.6-gke.13" \
	--machine-type "n1-standard-1" --image-type "COS" \
	--disk-type "pd-standard" --disk-size "20" \
	--metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/cloud-platform" \
	--num-nodes "2" \
	--enable-stackdriver-kubernetes \
	--enable-ip-alias \
	--network "projects/${PROJECT_ID}/global/networks/default" \
	--subnetwork "projects/${PROJECT_ID}/regions/europe-west2/subnetworks/default" \
	--default-max-pods-per-node "110" \
	--enable-autoscaling --min-nodes "1" --max-nodes "5" \
	--addons HorizontalPodAutoscaling,HttpLoadBalancing,KubernetesDashboard \
	--enable-autoupgrade \
	--enable-autorepair \
	--preemptible


# Can then get credentials with :
#
#   gcloud container clusters get-credentials standard-cluster-1 --zone europe-west2-a --project davidcallen
