#!/bin/bash

ARG_PRPL_PWD=$1

if [ "${ARG_PRPL_PWD}" == "" ] ; then
    echo "ERROR: mysql PRPL user pwd is needed"
    exit 1
fi

if [ ! -d db-backups ] ; then
    echo "ERROR: db-backups directory not found"
    exit 1
fi

mysqldump PRPL -h localhost -u PRPL --password=${ARG_PRPL_PWD} -B > ./db-backups/prpl-db-backup-`date +%Y-%m-%d-%H%M%S`.sql
