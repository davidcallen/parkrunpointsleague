#!/bin/bash
# 
# Delete mysql deployment
set -o nounset
set -o errexit

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| deploy-msqyl-delete.sh - Delete Mysql deployment and service in k8s  |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  ""
    echo  " Examples"
    echo  "    ./deploy-mysql-delete.sh"
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

echo "`date '+%Y%m%d %H:%M:%S'` : Deleting Mysql Deployment and Persistent Volume..."
echo
kubectl delete deployment,svc prpl-mysql || true
kubectl delete pvc mysql-pv-claim || true
kubectl delete pv mysql-pv-volume || true
