#!/bin/bash
# Example usage of container to start Icecream container
#
set -o nounset
set -o errexit

echo "`date '+%Y%m%d %H:%M:%S'` : Creating Persistent Volume..."
echo
kubectl apply -f deployment-mysql-pv.yaml
echo
echo "`date '+%Y%m%d %H:%M:%S'` : Creating MySQL..."
echo
kubectl apply -f deployment-mysql.yaml

# Can test attaching to the mysql pod with :
# kubectl run -it --rm --image=mysql:5.6 --restart=Never mysql-client -- mysql -h mysql -ppassword
