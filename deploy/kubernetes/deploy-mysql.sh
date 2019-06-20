#!/bin/bash
# 
# Deploy mysql 
set -o nounset
set -o errexit

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| deploy-msqyl.sh - Deploy Mysql deployment and service in k8s         |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright David C Allen.  2019 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  ""
    echo  " Examples"
    echo  "    ./deploy-mysql.sh"
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

echo "`date '+%Y%m%d %H:%M:%S'` : Creating Persistent Volume..."
echo
kubectl apply -f deployment-mysql-pv.yaml
echo
echo "`date '+%Y%m%d %H:%M:%S'` : Creating MySQL..."
echo
kubectl apply -f deployment-mysql.yaml

# Can test attaching to the mysql pod with :
# kubectl run -it --rm --image=mysql:5.7 --restart=Never mysql-client -- mysql -h prpl-mysql -u root -p<your-root-password-here>
