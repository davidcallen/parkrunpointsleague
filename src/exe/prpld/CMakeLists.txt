cmake_minimum_required (VERSION 2.6)
project (prpld)

set (PROJECT_INCLUDE_DIR ${PROJECT_SOURCE_DIR})
set (PROJECT_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

# --------------------------- sources --------------------------------------------------------------
set(PROJECT_SRCS
    ${PROJECT_SOURCE_DIR}/prpld.cpp
    ${PROJECT_SOURCE_DIR}/PRPLHTTPServerApplication.cpp
    ${PROJECT_SOURCE_DIR}/ResultsController.cpp
    ${PROJECT_SOURCE_DIR}/Scraper.cpp
    ${PROJECT_SOURCE_DIR}/ResultsScraper.cpp
    ${PROJECT_SOURCE_DIR}/EventHistoryScraper.cpp
    ${PROJECT_SOURCE_DIR}/Cache.cpp
    ${PROJECT_SOURCE_DIR}/EventHistoryCache.cpp
    ${PROJECT_SOURCE_DIR}/ResultsCache.cpp
    ${PROJECT_SOURCE_DIR}/HandlerFactory.cpp
    ${PROJECT_SOURCE_DIR}/LogFormatter.cpp
    ${PROJECT_SOURCE_DIR}/dataobject/Athlete.cpp
    ${PROJECT_SOURCE_DIR}/dataobject/Event.cpp
    ${PROJECT_SOURCE_DIR}/dataobject/EventLeague.cpp
    ${PROJECT_SOURCE_DIR}/dataobject/EventLeagueItem.cpp
    ${PROJECT_SOURCE_DIR}/dataobject/EventResult.cpp
    ${PROJECT_SOURCE_DIR}/dataobject/EventResultItem.cpp
    ${PROJECT_SOURCE_DIR}/dataobject/Param.cpp
    ${PROJECT_SOURCE_DIR}/datamodel/AthleteDataModel.cpp
    ${PROJECT_SOURCE_DIR}/datamodel/EventDataModel.cpp
    ${PROJECT_SOURCE_DIR}/datamodel/EventLeagueDataModel.cpp
    ${PROJECT_SOURCE_DIR}/datamodel/EventLeagueItemDataModel.cpp
    ${PROJECT_SOURCE_DIR}/datamodel/EventResultDataModel.cpp
    ${PROJECT_SOURCE_DIR}/datamodel/EventResultItemDataModel.cpp
    ${PROJECT_SOURCE_DIR}/requesthandlers/BaseHandler.cpp
    ${PROJECT_SOURCE_DIR}/requesthandlers/AthleteHandler.cpp
    ${PROJECT_SOURCE_DIR}/requesthandlers/EventLeagueHandler.cpp
    ${PROJECT_SOURCE_DIR}/requesthandlers/ForceResultsUpdateHandler.cpp
    ${PROJECT_SOURCE_DIR}/requesthandlers/FileRequestHandler.cpp
    ${PROJECT_SOURCE_DIR}/requesthandlers/GetLatestResultHandler.cpp
    ${PROJECT_SOURCE_DIR}/requesthandlers/HomePageHandler.cpp
    ${PROJECT_SOURCE_DIR}/requesthandlers/HealthPageHandler.cpp
)

# --------------------------- headers --------------------------------------------------------------
set(PROJECT_INCS
    ${PROJECT_SOURCE_DIR}/PRPLHTTPServerApplication.h
    ${PROJECT_SOURCE_DIR}/ResultsController.h
    ${PROJECT_SOURCE_DIR}/Scraper.h
    ${PROJECT_SOURCE_DIR}/ResultsScraper.h
    ${PROJECT_SOURCE_DIR}/EventHistoryScraper.h
    ${PROJECT_SOURCE_DIR}/Cache.h
    ${PROJECT_SOURCE_DIR}/EventHistoryCache.h
    ${PROJECT_SOURCE_DIR}/ResultsCache.h
    ${PROJECT_SOURCE_DIR}/HandlerFactory.h
    ${PROJECT_SOURCE_DIR}/LogFormatter.h
    ${PROJECT_SOURCE_DIR}/dataobject/Athlete.h
    ${PROJECT_SOURCE_DIR}/dataobject/Event.h
    ${PROJECT_SOURCE_DIR}/dataobject/EventLeague.h
    ${PROJECT_SOURCE_DIR}/dataobject/EventLeagueItem.h
    ${PROJECT_SOURCE_DIR}/dataobject/EventResult.h
    ${PROJECT_SOURCE_DIR}/dataobject/EventResultItem.h
    ${PROJECT_SOURCE_DIR}/dataobject/Param.h
    ${PROJECT_SOURCE_DIR}/datamodel/AthleteDataModel.h
    ${PROJECT_SOURCE_DIR}/datamodel/EventDataModel.h
    ${PROJECT_SOURCE_DIR}/datamodel/EventLeagueDataModel.h
    ${PROJECT_SOURCE_DIR}/datamodel/EventLeagueItemDataModel.h
    ${PROJECT_SOURCE_DIR}/datamodel/EventResultDataModel.h
    ${PROJECT_SOURCE_DIR}/datamodel/EventResultItemDataModel.h
    ${PROJECT_SOURCE_DIR}/requesthandlers/BaseHandler.h
    ${PROJECT_SOURCE_DIR}/requesthandlers/AthleteHandler.h
    ${PROJECT_SOURCE_DIR}/requesthandlers/EventLeagueHandler.h
    ${PROJECT_SOURCE_DIR}/requesthandlers/FileRequestHandler.h
    ${PROJECT_SOURCE_DIR}/requesthandlers/ForceResultsUpdateHandler.h
    ${PROJECT_SOURCE_DIR}/requesthandlers/GetLatestResultHandler.h
    ${PROJECT_SOURCE_DIR}/requesthandlers/HomePageHandler.h
    ${PROJECT_SOURCE_DIR}/requesthandlers/HealthPageHandler.h
)

# ---------------------------- resources -----------------------------------------------------------
if(WIN32)
    # set(PROJECT_RCS ${PROJECT_SOURCE_DIR}/prpl.rc)
    SOURCE_GROUP("Resource Files" FILES ${PROJECT_RCS})
endif(WIN32)

LINK_DIRECTORIES(
    ${CMAKE_BINARY_DIR}/../libs/lib
    ${CMAKE_BINARY_DIR}/../lib
    ${CMAKE_BINARY_DIR}
    ${PROJECT_BINARY_DIR}
)

include_directories("/usr/include")
include_directories("/usr/local/include")

set (EXTRA_LIBS
    PocoNet
    PocoNetSSL
    PocoUtil
    PocoXML
    PocoData
    PocoDataMySQL
    PocoFoundation
    gumbo
    tidy
    ${PRPL_EXTRA_LIBS_PTHREADS}
)

if (WIN32)
    add_definitions(-D_CONSOLE)
endif (WIN32)


# add the executable
add_executable(${PROJECT_NAME} ${PROJECT_SRCS} ${PROJECT_INCS} ${PROJECT_RCS})

set_target_properties(${PROJECT_NAME} PROPERTIES COMPILE_FLAGS "${PRPL_COMPILE_FLAGS_EXE}")
set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS "${PRPL_LINK_FLAGS_EXE}")
if (WIN32)
    set_target_properties(${PROJECT_NAME} PROPERTIES DEBUG_POSTFIX "d")
    set_target_properties(${PROJECT_NAME} PROPERTIES FOLDER "Executables")
endif (WIN32)

target_link_libraries (${PROJECT_NAME} ${EXTRA_LIBS})

# strip debug info from release build binaries (linux only)
if("${PRPL_UNIX_RELWITHDEBUG}" STREQUAL "TRUE")
    # unfortunately cmake "$<TARGET_FILE: " only available in cmake-2.8.8 upwards
    # COMMAND "${CMAKE_SOURCE_DIR}/strip-debug.sh" ARGS "$<TARGET_FILE:${PROJECT_NAME}>"
    add_custom_command(TARGET ${PROJECT_NAME}
        POST_BUILD
        COMMAND "${CMAKE_SOURCE_DIR}/strip-debug.sh" ARGS "${EXECUTABLE_OUTPUT_PATH}/${PROJECT_NAME}"
        WORKING_DIRECTORY "${EXECUTABLE_OUTPUT_PATH}"
    )
    set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${EXECUTABLE_OUTPUT_PATH}/.debug/${PROJECT_NAME}.debug")
endif("${PRPL_UNIX_RELWITHDEBUG}" STREQUAL "TRUE")

