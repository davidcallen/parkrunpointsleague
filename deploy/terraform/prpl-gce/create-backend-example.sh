gcloud beta compute health-checks create http prpl-http-basic-check \
--region=europe-west2 \
--use-serving-port


gcloud beta compute backend-services create prpl-backend-service \
--load-balancing-scheme=INTERNAL_MANAGED \
--protocol=HTTP \
--health-checks=prpl-http-basic-check \
--health-checks-region=europe-west2 \
--region=europe-west2

gcloud beta compute backend-services add-backend prpl-backend-service \
--balancing-mode=UTILIZATION \
--instance-group=prpl-service-manager \
--instance-group-zone=europe-west2-a \
--region=europe-west2

gcloud beta compute url-maps create prpl-url-map \
--default-service=prpl-backend-service \
--region=europe-west2

gcloud beta compute target-http-proxies create prpl-http-proxy \
--url-map=prpl-url-map \
--url-map-region=europe-west2 \
--region=europe-west2

gcloud beta compute forwarding-rules create prpl-forwarding-rule \
--load-balancing-scheme=INTERNAL_MANAGED \
--network=default \
--address=10.154.0.33 \
--ports=80 \
--region=europe-west2 \
--target-http-proxy=prpl-http-proxy \
--target-http-proxy-region=europe-west2
