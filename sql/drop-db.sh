#!/bin/bash

ARG_ROOT_PWD=$1

if [ "${ARG_ROOT_PWD}" == "" ] ; then
	echo "ERROR: mysql root user pwd is needed"
	exit 1
fi

cat drop-db.sql | mysql -h localhost -u root --password=${ARG_ROOT_PWD} -B 
