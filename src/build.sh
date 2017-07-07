#!/bin/bash
# +----------------------------------------------------------------------+
# | build - Build the product                                            |
# +----------------------------------------------------------------------+
#
# (C) Copyright parkrunpointsleague.org 2017 All Rights Reserved.
#
# Note : Assumes this script is being run from the src directory !!!!!!
set -o nounset

function usage()
{
    echo  "+----------------------------------------------------------------------+"
    echo  "| build - Build the product                                            |"
    echo  "+----------------------------------------------------------------------+"
    echo  ""
    echo  "(C) Copyright parkrunpointsleague.org 2015-2016 All Rights Reserved."
    echo  ""
    echo  "Usage: -h ^| [-debug] ^| [-clean | -noclean] | [ -cpu X] | [ -gmake] | [-gccver ??] [-icecc] [-codeblocks]"
    echo  ""
    echo  "    -h                 - Displays this help page."
    echo  "    -debug             - Builds in DEBUG mode"
    echo  "    -clean             - Builds with initial clean"
    echo  "    -noclean           - Builds without initial clean"
    echo  "    -cpu               - The number of CPU cores to use for multi-core builds (gnu make only)"
    echo  "    -gmake             - Force usage of gmake in preference to native make e.g. applies to solaris"
    echo  "    -gccver            - Force usage of particular gcc version e.g. use 44 to imply usage of gcc44 binary"
    echo  "    -icecc             - Use icecc for distributed builds (see doc for setup instructions)"
    echo  "    -codeblocks        - Ask CMake to generate codeblocks IDE project and the unix makefiles"
    echo  "    -nocmake           - Suppress running cmake. Useful for fast incremental builds."
    echo  "    -verbose           - Force verbose output"
    echo  ""
    echo  " Note : This script must be run from the src directory !!!!!!!!!!!"
    echo  ""
    exit 1
}

function buildReport()
{
    if [ "${TEE}" != "" ]
    then
    cd ${ROOT_PATH}/src
    echo "================================= BUILD SUMMARY ========================================"
    echo ""
    echo "----------------------------------- WARNINGS ------------------------------------------"
    cat make.log | grep "warning:"
    echo ""
    echo "-----------------------------------  ERRORS  ------------------------------------------"
    cat make.log | grep "make\[[0-9]\]: \*"
    cat make.log | grep "error:"
    echo ""
    echo "Warnings     : `cat make.log | grep -c \"warning:\"`"
    echo "Make Errors  : `cat make.log | grep -c \"make\[[0-9]\]: \*\"`"
    echo "Errors       : `cat make.log | grep -c \"error:\"`"
    echo "================================ BUILD SUMMARY END ====================================="
    fi
}

if [ "${1}" == "-h" ]
then
    usage
fi

# default arg variables
ARG_DEBUG=FALSE
ARG_CLEAN=
ARG_CPUS=
ARG_GMAKE=FALSE
ARG_GCC_VER=
ARG_ICECC=
ARG_CMAKE_CODEBLOCKS=FALSE
ARG_NOCMAKE=FALSE
ARG_VERBOSE=

# Get args
while (( "$#" )); do
    echo "arg=$1"
    ARG_RECOGNISED=FALSE
    if [ "$1" == "-debug" -o "$1" == "-d" ]; then
        ARG_DEBUG=TRUE
        ARG_RECOGNISED=TRUE
    fi
    if [ "$1" == "-noclean" ]; then
        ARG_CLEAN=FALSE
        ARG_RECOGNISED=TRUE
    fi
    if [ "$1" == "-clean" ]; then
        ARG_CLEAN=TRUE
        ARG_RECOGNISED=TRUE
    fi
    if [ "$1" == "-cpu" ]; then
        shift 1
        ARG_CPUS="-j $1"
        ARG_RECOGNISED=TRUE
    fi
    if [ "$1" == "-gmake" ]; then
        ARG_GMAKE=TRUE
        ARG_RECOGNISED=TRUE
    fi
    if [ "$1" == "-codeblocks" -o "$1" == "-cb" ]; then
        ARG_CMAKE_CODEBLOCKS=TRUE
        ARG_RECOGNISED=TRUE
    fi
    if [ "$1" == "-nocmake" -o "$1" == "-nc" ]; then
        ARG_NOCMAKE=TRUE
        ARG_RECOGNISED=TRUE
    fi
    if [ "$1" == "-gccver" -o "$1" == "-gv" ]; then
        shift 1
        ARG_GCC_VER=$1
        ARG_RECOGNISED=TRUE
    fi
    if [ "$1" == "-icecc" -o "$1" == "-ic" ]; then
        ARG_ICECC=TRUE
        ARG_RECOGNISED=TRUE
    fi
    if [ "$1" == "-verbose" -o "$1" == "-v" ]; then
        ARG_VERBOSE="VERBOSE=1"
        ARG_RECOGNISED=TRUE
    fi
    if [ "${ARG_RECOGNISED}" == "FALSE" ]; then
        echo "Invalid args : Unknown argument \"${1}\"."
        exit 1
    fi
    shift
done

# validate input args
if [ "${ARG_CLEAN}" == "" ]
then
    echo "Invalid args : specify either -clean or -noclean."
    exit 1
fi

# Choose debug mode
if [ "${ARG_DEBUG}" == "TRUE" ]
then
  DEBUG="TRUE"
  # Pass additional flavour name - useful for solaris to include flavour-specific makefiles
  FLAVOUR="debug"
  CMAKE_BUILD_TYPE="Debug"
else
  DEBUG=""
  # Pass additional flavour name - useful for solaris to include flavour-specific makefiles
  FLAVOUR="release"
  CMAKE_BUILD_TYPE="Release"
fi
if [ "${ARG_GCC_VER}" == "" ]
then
  CMAKE_GCC_VER=
else
  CMAKE_GCC_VER="-DGCC_VER=${ARG_GCC_VER}"
fi
if [ "${ARG_ICECC}" == "TRUE" ] ; then
  CMAKE_ICECC="-DICECC=TRUE"
else
  CMAKE_ICECC=
fi
if [ "${ARG_CMAKE_CODEBLOCKS}" == "TRUE" ] ; then
    CMAKE_GENERATOR="CodeBlocks - Unix Makefiles"
else
    CMAKE_GENERATOR="Unix Makefiles"
fi
echo CMAKE_GENERATOR=${CMAKE_GENERATOR}
ROOT_PATH=`pwd`/..


# -----------------------------------------------------
# Include common functions
. ${ROOT_PATH}/functions.sh

# Check on this platform
prpl_get_env $ROOT_PATH
EXIT_CODE=$?
if [ ${EXIT_CODE} -ne 0 ] ; then
    echo ERROR: could not get prpl environment
    exit ${EXIT_CODE}
fi
BUILD_PLATFORM=${PRPL_GET_ENV_UNAME_SYSTEM}


# -----------------------------------------------------
# Dependant on platform, decide on make utility
MAKE=make
if [ "${ARG_GMAKE}" == "TRUE" ]
then
    MAKE=gmake
fi
TEE=
which tee > /dev/null
if [ $? == 0 ]
then
    TEE=tee
fi
echo TEE=${TEE}

export LD_LIBRARY_PATH=.:${ROOT_PATH}/bin:${LD_LIBRARY_PATH}
echo LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH_64=${LD_LIBRARY_PATH}
echo LD_LIBRARY_PATH_64=${LD_LIBRARY_PATH_64}

# Note : for AIX you need a LIBPATH in your .bashrc of similar to this :
#        export LIBPATH=.:/opt/freeware/lib64/:/opt/freeware/lib:/lib:/usr/lib
if [ "${PRPL_GET_ENV_UNAME_SYSTEM}" == "AIX" ] ; then
    export LIBPATH=.:${ROOT_PATH}/bin:${LIBPATH}
    echo LIBPATH=${LIBPATH}
fi
DATE=`date`
echo "Building for BUILD_PLATFORM=${BUILD_PLATFORM} MAKE=${MAKE} DEBUG=${DEBUG} ..."
echo "Started at ${DATE}"
echo

if [ "${PRPL_GET_ENV_UNAME_SYSTEM}" == "SunOS" ]
then
    if [ "${MAKE}" == "make" ]
    then
        echo "NOTE: Dependency checking under SOLARIS only enabled with -gmake"
        echo
    fi
fi


# Keep a record of build choices e.g. compiler, make tool, debug etc...
echo -e "# Last Build at `date` with config : \n\n\
GCC_VER=${ARG_GCC_VER}\n\
BUILD_PLATFORM=${BUILD_PLATFORM}\n\
MAKE=${MAKE}\n\
DEBUG=${DEBUG}\n\
CLEAN=ARG_CLEAN\n" > build.info


# Clean cmake generated makefiles
if [ "${ARG_CLEAN}" == "TRUE" ]
then
	echo "Cleaning CMake cache files"
    cd ${ROOT_PATH}/src
    find . -name 'CMakeCache.txt' | xargs rm -f
    find . -name 'CMakeFiles' | xargs rm -r
fi

# Clean the bin dir and put the 3rd Party libs back in it
if [ "${ARG_CLEAN}" == "TRUE" ]
then
    cd ${ROOT_PATH}/src
    if [ -d ${ROOT_PATH}/bin/.debug ] ; then
        rm -rf ${ROOT_PATH}/bin/.debug
    fi
    rm ${ROOT_PATH}/bin/*
fi
if [ ! -d ${ROOT_PATH}/bin/.debug ] ; then
    mkdir ${ROOT_PATH}/bin/.debug
fi

# Ensure CMake generated makefiles are up to date
cd ${ROOT_PATH}/src
if [ "${ARG_NOCMAKE}" == "FALSE" ] ; then
    #CMAKE_C_COMPILER=cc CMAKE_CXX_COMPILER=CC CC=cc CXX=CC
    echo passing to cmake PLATFORM=${BUILD_PLATFORM}
    if [ "${ARG_ICECC}" == "TRUE" ] ; then
       export CC="icecc gcc${ARG_GCC_VER}"
       export CXX="icecc g++${ARG_GCC_VER}"
    fi

	if [ "${ARG_ICECC}" == "TRUE" ] ; then
		if [ ! -n "${CC+xxx}" ] ; then
			export CC="gcc"
		fi
		if [ ! -n "${CXX+xxx}" ] ; then
			export CXX="g++"
		fi
		# export PATH=/usr/lib64/icecc/bin:${PATH}
		export PATH=${PRPL_ICECC_BIN}:${PATH}
		echo "PATH=$PATH"
		# Set CPUs to a sensible amount to distribute throughout the icecream build cluster (unless overriden)
		if [ "${ARG_CPUS}" == "" ] ; then
			ARG_CPUS="-j 30"
		fi
		echo "Setting CC and CXX with -icecc : CC=${CC} CXX=${CXX} PATH=${PATH} ARG_CPUS=${ARG_CPUS}"
	fi
    
    # cmake -G "${CMAKE_GENERATOR}" -DPRPL_PLATFORM="${BUILD_PLATFORM}" -DPRPL_ARCH="${PRPL_GET_ENV_UNAME_PROCESSOR}" -DFLAVOUR="${FLAVOUR}" -DDEBUG="${DEBUG}" -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" -DBOOTSTRAP="TRUE" ${CMAKE_GCC_VER} ${CMAKE_ICECC} 

    echo LD_LIBRARY_PATH=$LD_LIBRARY_PATH
    which cmake

    cd ${ROOT_PATH}/src
    #CMAKE_C_COMPILER=cc CMAKE_CXX_COMPILER=CC CC=cc CXX=CC
    cmake -G  "${CMAKE_GENERATOR}" -DPRPL_PLATFORM="${BUILD_PLATFORM}" -DPRPL_ARCH="${PRPL_GET_ENV_UNAME_PROCESSOR}" -DFLAVOUR="${FLAVOUR}" -DDEBUG="${DEBUG}" -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" ${CMAKE_GCC_VER} ${CMAKE_ICECC}
    if [ $? -ne 0 ] ; then
        exit 1
    fi
else
	# Non-cmake dependant settings for ICECC
	if [ "${ARG_ICECC}" == "TRUE" ] ; then
		# Set CPUs to a sensible amount to distribute throughout the icecream build cluster (unless overriden)
		if [ "${ARG_CPUS}" == "" ] ; then
			ARG_CPUS="-j 30"
		fi
		echo "Setting for -icecc : ARG_CPUS=${ARG_CPUS}"

		if [ "${ARG_VERBOSE}" == "TRUE" ] ; then
			export ICECC_DEBUG=debug
		fi
	fi
fi

rm make.log > /dev/null
touch make.log

# Touch main file to update the build datetime within it
touch ${ROOT_PATH}/src/exe/prpld/PRPLHTTPServerApplication.cpp

cd ${ROOT_PATH}/src
if [ "${TEE}" == "" ]
then
    ${MAKE} -f Makefile ${ARG_VERBOSE} PLATFORM="${BUILD_PLATFORM}" FLAVOUR="${FLAVOUR}" DEBUG="${DEBUG}" ${ARG_CPUS}
    MAKE_EXIT_CODE=$?
else
#    ${MAKE} PLATFORM="${BUILD_PLATFORM}" FLAVOUR="${FLAVOUR}" DEBUG="${DEBUG}" ${ARG_CPUS} &> make_tmp.log
#    MAKE_EXIT_CODE=$?
#    cat make_tmp.log | tee -a ${ROOT_PATH}/src/make.log
    ${MAKE} -f Makefile ${ARG_VERBOSE} PLATFORM="${BUILD_PLATFORM}" FLAVOUR="${FLAVOUR}" DEBUG="${DEBUG}" ${ARG_CPUS}  2>&1 | tee -a ${ROOT_PATH}/src/make.log
    MAKE_EXIT_CODE=${PIPESTATUS[0]}
fi
buildReport
if [ $MAKE_EXIT_CODE -ne 0 ]
then
    exit $MAKE_EXIT_CODE
fi


FINISH_DATE=`date`
echo "Finished at ${FINISH_DATE}   (started on ${DATE})"
