#!/bin/bash

ARG_PRPL_PWD=$1

if [ "${ARG_PRPL_PWD}" == "" ] ; then
    echo "ERROR: mysql PRPL user pwd is needed"
    exit 1
fi

cat sample-data.sql | mysql -h localhost -u PRPL --password=${ARG_PRPL_PWD} -B 
