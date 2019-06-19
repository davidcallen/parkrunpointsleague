#!/bin/bash
#
# Create standard testing cluster. g1-small, 3 nodes, auto-scale (1-5 nodes)
PROJECT_ID=davidcallen

gcloud beta container --project "${PROJECT_ID}" clusters create "standard-cluster-1" \
	--zone "europe-west2-a" --no-enable-basic-auth --cluster-version "1.13.6-gke.6" \
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
