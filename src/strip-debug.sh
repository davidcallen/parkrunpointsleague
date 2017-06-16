#!/bin/bash
# +------------------------------------------------------------------------+
# | strip-debug - Split debug info from a release binary                   |
# +------------------------------------------------------------------------+
#
# (C) Copyright parkrunpointsleague.org 2017 All Rights Reserved.
#
# Note : This script is only intended to be run from the CMake Makefiles !!!!!!!!!!!

ARG_FILE=${1}

function usage()
{
    echo  "+------------------------------------------------------------------------+"
    echo  "| strip-debug - Split debug info from a release binary                   |"
    echo  "+------------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright parkrunpointsleague.org 2015-2016 All Rights Reserved."
    echo  ""
    echo  "Usage: "
    echo  ""
    echo  " Note : This script is only intended to be run from the CMake Makefiles !!!!!!!!!!!"
    echo  ""
    exit 1
}

ROOT_PATH=`pwd`/..

if [ ! -e .debug ]
then
    mkdir .debug
fi

function stripDebug()
{
    FILE=${1}
    DEBUG_FILE=${2}
    DEBUG_FILENAMEPATH=.debug/${DEBUG_FILE}.debug

    PROCEED=FALSE
    REASON=0
    if [ -e ${FILE} ]
    then
        if [ -e ${DEBUG_FILENAMEPATH} ]
        then
            if [ ${FILE} -nt ${DEBUG_FILENAMEPATH} ]
            then
                REASON=newer
                PROCEED=TRUE
            else
                REASON=up-to-date
            fi
        else
            REASON=missing
            PROCEED=TRUE
        fi
    else
        echo "  ERROR : File ${FILE} does not exist."
        exit 1
    fi

    if [ ${PROCEED} == "TRUE" ]
    then
        #echo "Checking ${FILE} to strip to ${DEBUG_FILE} - [${REASON}] : STRIPPING ..."
        echo "Stripping debug info from ${FILE}         [${REASON}]"
        if [ -e ${DEBUG_FILENAMEPATH} ]
        then
            # echo "Deleting ${DEBUG_FILE}.debug"
            rm ${DEBUG_FILENAMEPATH}
        fi
        objcopy --only-keep-debug ${FILE} ${DEBUG_FILENAMEPATH}
        EXIT_CODE=$?
        if [ $EXIT_CODE -ne 0 ]
        then
            exit $EXIT_CODE
        fi
        strip --strip-debug --strip-unneeded ${FILE}
        EXIT_CODE=$?
        if [ $EXIT_CODE -ne 0 ]
        then
            exit $EXIT_CODE
        fi
        objcopy --add-gnu-debuglink=${DEBUG_FILENAMEPATH} ${FILE}
        EXIT_CODE=$?
        if [ $EXIT_CODE -ne 0 ]
        then
            exit $EXIT_CODE
        fi
        # ensure the debug filename is marginally newer than the binary file, to prevent subsequent re-stripping
        touch ${DEBUG_FILENAMEPATH}
    else
        #echo "Checking ${FILE} to strip to ${DEBUG_FILE}   : IGNORING"
        echo "Ignoring ${FILE}          [${REASON}]"
    fi
}

DEBUG_FILE=$(basename "${ARG_FILE}")
FILE_EXTENSION="${DEBUG_FILE##*.}"
DEBUG_FILE="${DEBUG_FILE%.*}"

stripDebug ${ARG_FILE} ${DEBUG_FILE}
