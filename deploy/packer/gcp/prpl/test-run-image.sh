#!/bin/bash

gcloud compute instances create --image-family=prpl --machine-type=f1-micro --tags="http-server,https-server" prpl-02
