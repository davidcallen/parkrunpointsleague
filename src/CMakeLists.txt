cmake_minimum_required(VERSION 2.6)


# Suppress re-linking of dependant libraries for fast dev incremental builds (cmake v2.8.10 rc3 onwards)
if(UNIX)
    set(CMAKE_LINK_DEPENDS_NO_SHARED 1)
endif(UNIX)


# ----------------------------------- project PRPL -----------------------------------------------
project (prpl)

message(STATUS "PRPL_INFO : PRPL_PLATFORM=${PRPL_PLATFORM} PRPL_ARCH=${PRPL_ARCH} CMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME} CMAKE_SYSTEM_PROCESSOR=${CMAKE_SYSTEM_PROCESSOR}")

set(PRPL_ARCH_BITS "")
if ("${CMAKE_SYSTEM_PROCESSOR}" MATCHES "x86")
	set(PRPL_ARCH_BITS "32")
elseif ("${CMAKE_SYSTEM_PROCESSOR}" MATCHES "x86_64")
	set(PRPL_ARCH_BITS "64")
endif ()

if (${CMAKE_SYSTEM_PROCESSOR} MATCHES x86_64)
	set(PRPL_ARCH_BITS "64")
endif ()

message(STATUS "PRPL_INFO : PRPL_ARCH_BITS=${PRPL_ARCH_BITS}")


# --------------------------------- paths  ---------------------------------------------------
set(CMAKE_BINARY_DIR ${CMAKE_SOURCE_DIR}/../bin)

set(EXECUTABLE_OUTPUT_PATH ${CMAKE_BINARY_DIR})
if(WIN32)
    set(LIBRARY_OUTPUT_PATH ${CMAKE_SOURCE_DIR}/../lib)
else(WIN32) # Unix
    set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR})
endif(WIN32)

# Ensure windows outputs binaries directly into the bin and lib folders (not in Debug or Release subfolders)
if (WIN32)
    SET (CMAKE_ARCHIVE_OUTPUT_DIRECTORY  ${LIBRARY_OUTPUT_PATH} CACHE PATH "build directory")
    SET (CMAKE_RUNTIME_OUTPUT_DIRECTORY  ${EXECUTABLE_OUTPUT_PATH} CACHE PATH "build directory")
    if(WIN32)
      SET (CMAKE_LIBRARY_OUTPUT_DIRECTORY  ${EXECUTABLE_OUTPUT_PATH} CACHE PATH "build directory")
    else(WIN32)
      SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${LIBRARY_OUTPUT_PATH} CACHE PATH "build directory")
    endif(WIN32)

    # For each configuration (Debug, Release, MinSizeRel... and/or anything the user chooses)
    foreach(CONF ${CMAKE_CONFIGURATION_TYPES})
        # Go uppercase (DEBUG, RELEASE...)
        STRING(TOUPPER "${CONF}" CONF)
        SET("CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${CONF}" "${LIBRARY_OUTPUT_PATH}")
        SET("CMAKE_RUNTIME_OUTPUT_DIRECTORY_${CONF}" "${EXECUTABLE_OUTPUT_PATH}")
        if(WIN32)
          SET("CMAKE_LIBRARY_OUTPUT_DIRECTORY_${CONF}" "${EXECUTABLE_OUTPUT_PATH}")
        else()
          SET("CMAKE_LIBRARY_OUTPUT_DIRECTORY_${CONF}" "${LIBRARY_OUTPUT_PATH}")
        endif()
        message(STATUS "PRPL_INFO : CMAKE_RUNTIME_OUTPUT_DIRECTORY_${CONF}=${CMAKE_RUNTIME_OUTPUT_DIRECTORY_${CONF}}")
        message(STATUS "PRPL_INFO : CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${CONF}=${CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${CONF}}")
        message(STATUS "PRPL_INFO : CMAKE_LIBRARY_OUTPUT_DIRECTORY_${CONF}=${CMAKE_LIBRARY_OUTPUT_DIRECTORY_${CONF}}")
    endforeach()
endif (WIN32)

message(STATUS "PRPL_INFO : CMAKE_RUNTIME_OUTPUT_DIRECTORY=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
message(STATUS "PRPL_INFO : CMAKE_ARCHIVE_OUTPUT_DIRECTORY=${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}")
message(STATUS "PRPL_INFO : CMAKE_LIBRARY_OUTPUT_DIRECTORY=${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")

set(PROJECT_INCLUDE_DIR ${PROJECT_SOURCE_DIR})

set(3RD_PARTY_DIR ${CMAKE_SOURCE_DIR}/3rd-party)

# Unix : Ensure we dont link with RPATH specified
if(UNIX)
    set(CMAKE_SKIP_RPATH TRUE)
    set(CMAKE_SKIP_INSTALL_RPATH TRUE)
    set(CMAKE_SKIP_BUILD_RPATH TRUE)
endif(UNIX)

# Prevent CMake generating custom build steps for CMakeLists.txt, and slowing down the Windows Incredibuild building.
# A side-effect of this is that changes to CMakeLists.txt will not be automatically detected by VisualStudio builds.
if(WIN32)
    set(CMAKE_SUPPRESS_REGENERATION TRUE)
endif(WIN32)

if (CMAKE_BUILD_TYPE MATCHES Release)
    message(STATUS "PRPL_INFO : CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} Release")
else (CMAKE_BUILD_TYPE MATCHES Release)
    message(STATUS "PRPL_INFO : CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} Debug")
endif (CMAKE_BUILD_TYPE MATCHES Release)

# --------------------- preprocessor definitions ---------------------------------------------------

add_definitions("-D_REENTRANT")
add_definitions("-DPOCO_LOG_DEBUG")

if (WIN32)
    add_definitions("-D_CRT_SECURE_NO_DEPRECATE")
    if("${PRPL_ARCH}" STREQUAL "64")
        add_definitions("-DWIN64 -D_WIN64")
    endif()
endif (WIN32)

if (UNIX)
    if (CMAKE_BUILD_TYPE MATCHES Release)
        add_definitions("-DNDEBUG")
    else (CMAKE_BUILD_TYPE MATCHES Release)
        add_definitions("-D_DEBUG")
    endif (CMAKE_BUILD_TYPE MATCHES Release)

    # add_definitions("-D${OS} -D${CMAKE_SYSTEM_PROCESSOR} -DPRPL_PLATFORM=${PRPL_PLATFORM}")
endif (UNIX)

# --------------------- compiler + linker flags  ---------------------------------------------------

message(STATUS "PRPL_INFO : CMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME} CMAKE_SYSTEM_PROCESSOR=${CMAKE_SYSTEM_PROCESSOR} PRPL_PLATFORM=${PRPL_PLATFORM}")
message(STATUS "PRPL_INFO : Initial CMAKE_C_COMPILER=${CMAKE_C_COMPILER}")
message(STATUS "PRPL_INFO : Initial CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}")
message(STATUS "PRPL_INFO : Initial CMAKE_C_FLAGS=${CMAKE_C_FLAGS}")
message(STATUS "PRPL_INFO : Initial CMAKE_C_FLAGS_DEBUG=${CMAKE_C_FLAGS_DEBUG}")
message(STATUS "PRPL_INFO : Initial CMAKE_C_FLAGS_RELEASE=${CMAKE_C_FLAGS_RELEASE}")
message(STATUS "PRPL_INFO : Initial CMAKE_C_FLAGS_RELWITHDEBINFO=${CMAKE_C_FLAGS_RELWITHDEBINFO}")
message(STATUS "PRPL_INFO : Initial CMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}")
message(STATUS "PRPL_INFO : Initial CMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG}")
message(STATUS "PRPL_INFO : Initial CMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}")
message(STATUS "PRPL_INFO : Initial CMAKE_CXX_FLAGS_RELWITHDEBINFO=${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")

message(STATUS "PRPL_INFO : Initial CMAKE_EXE_LINKER_FLAGS=${CMAKE_EXE_LINKER_FLAGS}")
message(STATUS "PRPL_INFO : Initial CMAKE_EXE_LINKER_FLAGS_DEBUG=${CMAKE_EXE_LINKER_FLAGS_DEBUG}")
message(STATUS "PRPL_INFO : Initial CMAKE_EXE_LINKER_FLAGS_RELEASE=${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
message(STATUS "PRPL_INFO : Initial CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO=${CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO}")
message(STATUS "PRPL_INFO : Initial CMAKE_SHARED_LINKER_FLAGS=${CMAKE_SHARED_LINKER_FLAGS}")
message(STATUS "PRPL_INFO : Initial CMAKE_SHARED_LINKER_FLAGS_DEBUG=${CMAKE_SHARED_LINKER_FLAGS_DEBUG}")
message(STATUS "PRPL_INFO : Initial CMAKE_SHARED_LINKER_FLAGS_RELEASE=${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
message(STATUS "PRPL_INFO : Initial CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO=${CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO}")
message(STATUS "PRPL_INFO : Initial CMAKE_STATIC_LINKER_FLAGS=${CMAKE_STATIC_LINKER_FLAGS}")
message(STATUS "PRPL_INFO : Initial CMAKE_STATIC_LINKER_FLAGS_DEBUG=${CMAKE_STATIC_LINKER_FLAGS_DEBUG}")
message(STATUS "PRPL_INFO : Initial CMAKE_STATIC_LINKER_FLAGS_RELEASE=${CMAKE_STATIC_LINKER_FLAGS_RELEASE}")
message(STATUS "PRPL_INFO : Initial CMAKE_STATIC_LINKER_FLAGS_RELWITHDEBINFO=${CMAKE_STATIC_LINKER_FLAGS_RELWITHDEBINFO}")

set(PRPL_UNIX_RELWITHDEBUG "FALSE")
if(WIN32)
    # Compiling Flags :
    #
    # /EHsc - Enable C++ Exceptions Handling : Yes
    # /Gm   - Enable minimal rebuild : Yes
    # /W3   - Warning Level : 3
    # /Zi   - Debug Information Format = Program Database
    # /O2   - Optimization : Max Speed
    # /Od   - Optimization : Disabled
    # /Ob0  - Inline Function Expansion : Disabled
    # /Ob2  - Inline Function Expansion : Any suitable
    # /GL   - Whole Program Optimization (NOT USED since slow builds !)
    # /we   - Elevate warning to error (/we4172 /we4715 /we4717 /we4800)
    # /SAFESEH:NO   - Visual Studio 2012 and 2013

    # For MSVC90, avoid explicitly setting any default settings since can cause very slow linking (esp. in BOB).
    # MSVC90 will set some settings such as /O2 (or appear to) in Release mode anyway.
    if(WIN32)
        if(MSVC90)
            # Replace CMAKE default settings for compile/linking with a reduced set.
            # NOTE: this may need to be reviewed with future versions of CMAKE (currently using 2.8.9)
            set(CMAKE_C_FLAGS "/DWIN32 /D_WINDOWS /W3")
            set(CMAKE_C_FLAGS_RELEASE "/MD /DNDEBUG")
            set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELEASE}")
            set(CMAKE_CXX_FLAGS "/DWIN32 /D_WINDOWS /W3 /EHsc")
            set(CMAKE_CXX_FLAGS_RELEASE "/MD /DNDEBUG")
            set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELEASE}")
            if("${PRPL_ARCH}" STREQUAL "32")
                set(CMAKE_EXE_LINKER_FLAGS "/machine:x86")
            else()
                set(CMAKE_EXE_LINKER_FLAGS "/machine:x64")
            endif()
            set(CMAKE_EXE_LINKER_FLAGS_RELEASE "")
            set(CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_EXE_LINKER_FLAGS_RELEASE} /DEBUG")
            if("${PRPL_ARCH}" STREQUAL "32")
                set(CMAKE_SHARED_LINKER_FLAGS "/machine:x86")
            else()
                set(CMAKE_SHARED_LINKER_FLAGS "/machine:x64")
            endif()
            set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "")
            set(CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /DEBUG")
            set(CMAKE_STATIC_LINKER_FLAGS "")
            set(CMAKE_STATIC_LINKER_FLAGS_RELEASE "")
            set(CMAKE_STATIC_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_STATIC_LINKER_FLAGS_RELEASE} /DEBUG")
        endif(MSVC90)
        if(MSVC11 OR MSVC12)
            set(CMAKE_EXE_LINKER_FLAGS "/SAFESEH:NO")
            set(CMAKE_SHARED_LINKER_FLAGS "/SAFESEH:NO")
        endif(MSVC11 OR MSVC12)
    endif(WIN32)

    set(PRPL_C_FLAGS "/EHsc /W3 /we4172 /we4715 /we4717 /we4800")
    set(PRPL_C_FLAGS_DEBUG "${PRPL_C_FLAGS_DEBUG} /Gm /Zi")
    if(MSVC90)
        # For MSVC90, avoid explicitly setting /O2 since can cause very slow linking (esp. in BOB)
        # MSVC90 will set /O2 (or appear to) in Release mode anyway.
        #   set(PRPL_C_FLAGS_RELEASE "${PRPL_C_FLAGS_RELEASE} /O2")

        # /GL   - Whole Program Optimization (NOT USED since slow builds !)
        #   set(PRPL_C_FLAGS_RELEASE "${PRPL_C_FLAGS_RELEASE} /GL")
    else(MSVC90)
        set(PRPL_C_FLAGS_RELEASE "${PRPL_C_FLAGS_RELEASE} /O2")
        set(PRPL_C_FLAGS_RELWITHDEBINFO "${PRPL_C_FLAGS_RELEASE} /Zi")
    endif(MSVC90)
    set(PRPL_CXX_FLAGS "${PRPL_C_FLAGS}")
    set(PRPL_CXX_FLAGS_DEBUG "${PRPL_C_FLAGS_DEBUG}")
    set(PRPL_CXX_FLAGS_RELEASE "${PRPL_C_FLAGS_RELEASE}")
    set(PRPL_CXX_FLAGS_RELWITHDEBINFO "${PRPL_CXX_FLAGS_RELEASE}")


    # Linking Flags :
    #
    # /LTCG                 - Link Time Code Generation : Enabled
    # /DYNAMICBASE:NO       - Randomized Base Address
    # /OPT:REF              - Eliminate Unreferenced Data (/OPT:REF)
    # /OPT:ICF              - Remove Redundant COMDATs (/OPT:ICF)
    # /MACHINE:X86          - Target Machine Machine X86
    # /ERRORREPORT:PROMPT   - Error Reporting
    # /NXCOMPAT             - Compatible with Data Execution Prevention (on by default)
    # /LARGEADDRESSAWARE    - Application can handle addresses larger than 2 gigabytes. (Used for 32-bit EXE linking)
    # /DEBUG                - Generate Debug Info
    # /MD                   - Use Multithread and DLL-specific runtime library
    # /FORCE:MULTIPLE       - Visual Studio 2010, 2012 and 2013
    set(PRPL_COMMON_LINKER_FLAGS "/DYNAMICBASE:NO")
    # For MSVC90, avoid explicitly setting any default settings since can cause very slow linking (esp. in BOB).
    # MSVC90 will set some settings such as /O2 (or appear to) in Release mode anyway.
    if(NOT MSVC90)
        set(PRPL_COMMON_LINKER_FLAGS "${PRPL_COMMON_LINKER_FLAGS} /INCREMENTAL:NO")
    endif(NOT MSVC90)
    if(MSVC10 OR MSVC11 OR MSVC12)
        set(PRPL_COMMON_LINKER_FLAGS "${PRPL_COMMON_LINKER_FLAGS} /FORCE:MULTIPLE")
    endif(MSVC10 OR MSVC11 OR MSVC12)
    set(PRPL_COMMON_LINKER_FLAGS_RELEASE "/OPT:REF /OPT:ICF")
    set(PRPL_COMMON_LINKER_FLAGS_RELEASE "${PRPL_COMMON_LINKER_FLAGS_RELEASE} /INCREMENTAL:NO /LTCG")
    set(PRPL_COMMON_LINKER_FLAGS_RELWITHDEBINFO "/OPT:REF /OPT:ICF /INCREMENTAL:YES /DEBUG")

    if("${PRPL_ARCH}" STREQUAL "32")
        set(PRPL_COMMON_LINKER_FLAGS "${PRPL_COMMON_LINKER_FLAGS} /MACHINE:X86")
    else()
        set(PRPL_COMMON_LINKER_FLAGS "${PRPL_COMMON_LINKER_FLAGS} /MACHINE:X64")
    endif()
    set(PRPL_SHARED_LINKER_FLAGS "${PRPL_COMMON_LINKER_FLAGS}")
    set(PRPL_SHARED_LINKER_FLAGS_DEBUG "${PRPL_COMMON_LINKER_FLAGS_DEBUG}")
    set(PRPL_SHARED_LINKER_FLAGS_RELEASE "${PRPL_COMMON_LINKER_FLAGS_RELEASE}")
    set(PRPL_SHARED_LINKER_FLAGS_RELWITHDEBINFO "${PRPL_COMMON_LINKER_FLAGS_RELWITHDEBINFO}")
    set(PRPL_STATIC_LINKER_FLAGS "${PRPL_COMMON_LINKER_FLAGS}")
    set(PRPL_STATIC_LINKER_FLAGS_DEBUG "${PRPL_COMMON_LINKER_FLAGS_DEBUG}")
    set(PRPL_STATIC_LINKER_FLAGS_RELEASE "${PRPL_COMMON_LINKER_FLAGS_RELEASE}")
    set(PRPL_STATIC_LINKER_FLAGS_RELWITHDEBINFO "${PRPL_COMMON_LINKER_FLAGS_RELWITHDEBINFO}")
    set(PRPL_EXE_LINKER_FLAGS "${PRPL_COMMON_LINKER_FLAGS} /ERRORREPORT:PROMPT")
    if("${PRPL_ARCH}" STREQUAL "32")
        set(PRPL_EXE_LINKER_FLAGS "${PRPL_EXE_LINKER_FLAGS} /LARGEADDRESSAWARE")
    endif()
    set(PRPL_EXE_LINKER_FLAGS_DEBUG "${PRPL_COMMON_LINKER_FLAGS_DEBUG}")
    set(PRPL_EXE_LINKER_FLAGS_RELEASE "${PRPL_COMMON_LINKER_FLAGS_RELEASE}")
    set(PRPL_EXE_LINKER_FLAGS_RELWITHDEBINFO "${PRPL_COMMON_LINKER_FLAGS_RELWITHDEBINFO}")
endif(WIN32)



if (UNIX)
	message(STATUS "PRPL_INFO : setting UNIX compiler settings")
    if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
        # Compiling
        set(PRPL_C_FLAGS "${PRPL_C_FLAGS} -Wreturn-type")
        if (${PRPL_ARCH} STREQUAL "32")
            set(PRPL_C_FLAGS "${PRPL_C_FLAGS} -m32")
        elseif (${PRPL_ARCH} STREQUAL "64")
            set(PRPL_C_FLAGS "${PRPL_C_FLAGS} -m64")
        endif ()

        if (CMAKE_BUILD_TYPE MATCHES Release)
            set(PRPL_UNIX_RELWITHDEBUG "TRUE")
            set(PRPL_C_FLAGS_RELEASE "${PRPL_C_FLAGS_RELEASE} -O2 -g")
        else ()
            set(PRPL_C_FLAGS_DEBUG "${PRPL_C_FLAGS_DEBUG} -g -O0 -Wall")
        endif ()
        set(PRPL_CXX_FLAGS "${PRPL_C_FLAGS}")
        set(PRPL_CXX_FLAGS_DEBUG "${PRPL_C_FLAGS_DEBUG}")
        set(PRPL_CXX_FLAGS_RELEASE "${PRPL_C_FLAGS_RELEASE}")

        set(PRPL_COMPILE_FLAGS_SHARED "-fPIC -shared")
        set(PRPL_COMPILE_FLAGS_STATIC "-fPIC")

        # Linking
        if (${PRPL_ARCH} STREQUAL "32")
            set(PRPL_EXE_LINKER_FLAGS "${PRPL_EXE_LINKER_FLAGS} -m32")
        elseif (${PRPL_ARCH} STREQUAL "64")
            set(PRPL_EXE_LINKER_FLAGS "${PRPL_EXE_LINKER_FLAGS} -m64")
        endif ()
        set(PRPL_SHARED_LINKER_FLAGS "${PRPL_EXE_LINKER_FLAGS} -fPIC -dynamic -rdynamic")
        set(PRPL_STATIC_LINKER_FLAGS "")
        
    elseif (${CMAKE_SYSTEM_NAME} MATCHES "SOLARIS")
        # Compiling
        if (${PRPL_ARCH} STREQUAL "32")
            set(PRPL_C_FLAGS "${PRPL_C_FLAGS} -m32")
        elseif (${PRPL_ARCH} STREQUAL "64")
            set(PRPL_C_FLAGS "${PRPL_C_FLAGS} -m64")
        endif ()

        set(PRPL_C_FLAGS "${PRPL_C_FLAGS} -mt -KPIC") # -KPIC automatically provided by cmake
        if (CMAKE_BUILD_TYPE MATCHES Release)
            set(PRPL_C_FLAGS_RELEASE "${PRPL_C_FLAGS_RELEASE} -O4")
        else (CMAKE_BUILD_TYPE MATCHES Release)
            set(PRPL_C_FLAGS_DEBUG "${PRPL_C_FLAGS_DEBUG} -O0")
        endif ()
        set(PRPL_CXX_FLAGS "${PRPL_C_FLAGS}")
        set(PRPL_CXX_FLAGS_DEBUG "${PRPL_C_FLAGS_DEBUG}")
        set(PRPL_CXX_FLAGS_RELEASE "${PRPL_C_FLAGS_RELEASE}")

        set(PRPL_COMPILE_FLAGS_SHARED "-KPIC")
        set(PRPL_COMPILE_FLAGS_STATIC "-KPIC")

        # Linking
        if (${PRPL_ARCH} STREQUAL "32")
            set(PRPL_EXE_LINKER_FLAGS "${PRPL_EXE_LINKER_FLAGS} -m32")
        elseif (${PRPL_ARCH} STREQUAL "64")
            set(PRPL_EXE_LINKER_FLAGS "${PRPL_EXE_LINKER_FLAGS} -m64")
        endif ()
        set(PRPL_SHARED_LINKER_FLAGS "${PRPL_EXE_LINKER_FLAGS} -mt -Bdynamic -D_REENTRANT") # -KPIC and -G automatically provided by cmake
        set(PRPL_STATIC_LINKER_FLAGS "${PRPL_EXE_LINKER_FLAGS} -KPIC")

        set(EXTRA_LIBS ${EXTRA_LIBS} "-lrt")
    endif ()
endif (UNIX)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${PRPL_C_FLAGS}")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} ${PRPL_C_FLAGS_DEBUG}")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} ${PRPL_C_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO} ${PRPL_C_FLAGS_RELWITHDEBINFO}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${PRPL_CXX_FLAGS}")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${PRPL_CXX_FLAGS_DEBUG}")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${PRPL_CXX_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} ${PRPL_CXX_FLAGS_RELWITHDEBINFO}")

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${PRPL_EXE_LINKER_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} ${PRPL_EXE_LINKER_FLAGS_DEBUG}")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} ${PRPL_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO} ${PRPL_LINKER_FLAGS_EXE_RELWITHDEBINFO}")

set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${PRPL_SHARED_LINKER_FLAGS}")
set(CMAKE_SHARED_LINKER_FLAGS_DEBUG "${CMAKE_SHARED_LINKER_FLAGS_DEBUG} ${PRPL_SHARED_LINKER_FLAGS_DEBUG}")
set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} ${PRPL_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO} ${PRPL_SHARED_LINKER_FLAGS_RELWITHDEBINFO}")
set(CMAKE_STATIC_LINKER_FLAGS "${CMAKE_STATIC_LINKER_FLAGS} ${PRPL_STATIC_LINKER_FLAGS}")
set(CMAKE_STATIC_LINKER_FLAGS_DEBUG "${CMAKE_STATIC_LINKER_FLAGS_DEBUG} ${PRPL_STATIC_LINKER_FLAGS_DEBUG}")
set(CMAKE_STATIC_LINKER_FLAGS_RELEASE "${CMAKE_STATIC_LINKER_FLAGS_RELEASE} ${PRPL_STATIC_LINKER_FLAGS_RELEASE}")
set(CMAKE_STATIC_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_STATIC_LINKER_FLAGS_RELWITHDEBINFO} ${PRPL_STATIC_LINKER_FLAGS_RELWITHDEBINFO}")

message(STATUS "PRPL_INFO : After CMAKE_C_FLAGS=${CMAKE_C_FLAGS}")
message(STATUS "PRPL_INFO : After CMAKE_C_FLAGS_DEBUG=${CMAKE_C_FLAGS_DEBUG}")
message(STATUS "PRPL_INFO : After CMAKE_C_FLAGS_RELEASE=${CMAKE_C_FLAGS_RELEASE}")
message(STATUS "PRPL_INFO : After CMAKE_C_FLAGS_RELWITHDEBINFO=${CMAKE_C_FLAGS_RELWITHDEBINFO}")
message(STATUS "PRPL_INFO : After CMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}")
message(STATUS "PRPL_INFO : After CMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG}")
message(STATUS "PRPL_INFO : After CMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}")
message(STATUS "PRPL_INFO : After CMAKE_CXX_FLAGS_RELWITHDEBINFO=${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")

message(STATUS "PRPL_INFO : After CMAKE_EXE_LINKER_FLAGS=${CMAKE_EXE_LINKER_FLAGS}")
message(STATUS "PRPL_INFO : After CMAKE_EXE_LINKER_FLAGS_DEBUG=${CMAKE_EXE_LINKER_FLAGS_DEBUG}")
message(STATUS "PRPL_INFO : After CMAKE_EXE_LINKER_FLAGS_RELEASE=${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
message(STATUS "PRPL_INFO : After CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO=${CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO}")
message(STATUS "PRPL_INFO : After CMAKE_SHARED_LINKER_FLAGS=${CMAKE_SHARED_LINKER_FLAGS}")
message(STATUS "PRPL_INFO : After CMAKE_SHARED_LINKER_FLAGS_DEBUG=${CMAKE_SHARED_LINKER_FLAGS_DEBUG}")
message(STATUS "PRPL_INFO : After CMAKE_SHARED_LINKER_FLAGS_RELEASE=${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
message(STATUS "PRPL_INFO : After CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO=${CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO}")
message(STATUS "PRPL_INFO : After CMAKE_STATIC_LINKER_FLAGS=${CMAKE_STATIC_LINKER_FLAGS}")
message(STATUS "PRPL_INFO : After CMAKE_STATIC_LINKER_FLAGS_DEBUG=${CMAKE_STATIC_LINKER_FLAGS_DEBUG}")
message(STATUS "PRPL_INFO : After CMAKE_STATIC_LINKER_FLAGS_RELEASE=${CMAKE_STATIC_LINKER_FLAGS_RELEASE}")
message(STATUS "PRPL_INFO : After CMAKE_STATIC_LINKER_FLAGS_RELWITHDEBINFO=${CMAKE_STATIC_LINKER_FLAGS_RELWITHDEBINFO}")

# --------------------- misc   ------------------------------------------------

if (WIN32)
    SET(CMAKE_SHARED_LIBRARY_PREFIX "")
    SET(CMAKE_STATIC_LIBRARY_PREFIX "")
    SET(CMAKE_DEBUG_POSTFIX "d")
endif (WIN32)

# MySQL architecture dependant info
set(PRPL_MYSQL "TRUE")
set(PRPL_MYSQL_APPS "TRUE")

message(STATUS "PRPL_INFO : BEFORE PRPL_MYSQL_EMBEDDED_LINKED=${PRPL_MYSQL_EMBEDDED_LINKED}")

# Check if linking to the embedded library (for development purposes - gives connection to BOTH embedded and remote mysqld)
if(DEFINED PRPL_MYSQL_EMBEDDED_LINKED)
    # build.bat will set PRPL_MYSQL_EMBEDDED_LINKED if the shell has environment variable PRPL_MYSQL_EMBEDDED_LINKED
    set(PRPL_MYSQL_EMBEDDED_LINKED "${PRPL_MYSQL_EMBEDDED_LINKED}")
else(DEFINED PRPL_MYSQL_EMBEDDED_LINKED)
    set(PRPL_MYSQL_EMBEDDED_LINKED "FALSE")
endif(DEFINED PRPL_MYSQL_EMBEDDED_LINKED)
message(STATUS "PRPL_INFO : PRPL_MYSQL_EMBEDDED_LINKED=${PRPL_MYSQL_EMBEDDED_LINKED}")

if(${PRPL_MYSQL} STREQUAL "TRUE")
    message(STATUS "PRPL_INFO : MYSQL")
    # MySQL : includes, libs, lib dirs
    if(${PRPL_MYSQL_EMBEDDED_LINKED} STREQUAL "TRUE")
        if(UNIX)
            # For embedded mysql link to "mysqld", otherwise mysqlclient_r
            set(PRPL_EXTRA_LIBS_MYSQL
                mysqld
            )
            set(PRPL_LINK_DIRS_MYSQL ${LIBRARY_OUTPUT_PATH})
        else(UNIX)
            # libmariadb for mariadb
            # libmysql for mysql (not libmysqlclient - that is for static linking only)
            set(PRPL_EXTRA_LIBS_MYSQL
                libmysqld
            )
            set(PRPL_LINK_DIRS_MYSQL ${3RD_PARTY_DIR}/mysql/lib)
        endif(UNIX)
    else(${PRPL_MYSQL_EMBEDDED_LINKED} STREQUAL "TRUE")
        if(UNIX)
            # For embedded mysql link to "mysqld", otherwise mysqlclient_r
            set(PRPL_EXTRA_LIBS_MYSQL
                mysqlclient_r
            )
            set(PRPL_LINK_DIRS_MYSQL ${LIBRARY_OUTPUT_PATH})
        else(UNIX)
            # libmariadb for mariadb
            # libmysql for mysql (not libmysqlclient - that is for static linking only)
            set(PRPL_EXTRA_LIBS_MYSQL
                libmysql
            )
        set(PRPL_LINK_DIRS_MYSQL ${3RD_PARTY_DIR}/mysql/lib)
        endif(UNIX)
    endif(${PRPL_MYSQL_EMBEDDED_LINKED} STREQUAL "TRUE")

    set(PRPL_INCLUDES_MYSQL ${3RD_PARTY_DIR}/mysql/include)
endif(${PRPL_MYSQL} STREQUAL "TRUE")

# --------------------- include directories --------------------------------------------------------

include_directories("${CMAKE_SOURCE_DIR}/../libs/include")
include_directories("/usr/include")
include_directories("/usr/local/include")
include_directories("${CMAKE_SOURCE_DIR}/apps")


# --------------------- lib directories ------------------------------------------------------------

if (WIN32)
    link_directories(
        ${LINK_DIRECTORIES}
    )
else(WIN32)
    link_directories(
        ${CMAKE_BINARY_DIR}
        ${LINK_DIRECTORIES}
    )
endif(WIN32)


# turn on using solution folders
if (WIN32)
    if(NOT MSVC71)
        set_property(GLOBAL PROPERTY USE_FOLDERS ON)
    endif(NOT MSVC71)
endif (WIN32)

# --------------------- subdirectories --------------------------------------------------------------

add_subdirectory(exe)

# If want Poco source code built with prpl
# add_subdirectory(poco)
