#!/bin/bash
# +----------------------------------------------------------------------+
# | functions : General functions for shell scripts                      |
# +----------------------------------------------------------------------+
#
#


#----------------------------------------------------------------------------------
# Check for prpl environment
function prpl_get_env()
{
    # Input Args
    PRPL_GET_ENV_PRPL_ROOT=$1
    # Validate input args
    if [ "${PRPL_GET_ENV_PRPL_ROOT}" == "" ] ; then
        echo "ERROR: invalid args for prpl_get_env function. Specify the PRPL_ROOT filepath."
        PRPL_GET_ENV_EXIT_CODE=1
        return ${PRPL_GET_ENV_EXIT_CODE}
    fi
    if [ ! -d "${PRPL_GET_ENV_PRPL_ROOT}" ] ; then
        echo "ERROR: invalid args for prpl_get_env function. PRPL_ROOT directory does not exist."
        PRPL_GET_ENV_EXIT_CODE=1
        return ${PRPL_GET_ENV_EXIT_CODE}
    fi
    # Return variables - defaulting
    PRPL_GET_ENV_EXIT_CODE=0
    PRPL_GET_ENV_UNAME_SYSTEM=

    PRPL_GET_ENV_UNAME_SYSTEM=`uname -s`
    PRPL_GET_ENV_UNAME_PROCESSOR=`uname -p`

    return ${PRPL_GET_ENV_EXIT_CODE}
}
