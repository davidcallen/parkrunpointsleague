#!/bin/bash
# Example usage of container to start Icecream container
#
set -o nounset
set -o errexit

echo "`date '+%Y%m%d %H:%M:%S'` : Deleting Mysql Deployment and Persistent Volume..."
echo
kubectl delete deployment,svc prpl-mysql
kubectl delete pvc mysql-pv-claim
kubectl delete pv mysql-pv-volume
