#!/bin/bash
# This script desigined to be called only be systemd
# Source the /etc/sysconfig/jenkins file for us - to set our env vars

# Set our defaults
JENKINS_HOME="/var/lib/jenkins"
JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"
JENKINS_USER="jenkins"
JENKINS_PORT="8080"
JENKINS_LISTEN_ADDRESS=""
JENKINS_HTTPS_PORT=""
JENKINS_HTTPS_KEYSTORE=""
JENKINS_HTTPS_KEYSTORE_PASSWORD=""
JENKINS_HTTPS_LISTEN_ADDRESS=""
JENKINS_HTTP2_PORT=""
JENKINS_HTTP2_LISTEN_ADDRESS=""
JENKINS_DEBUG_LEVEL="5"
JENKINS_ENABLE_ACCESS_LOG="no"
JENKINS_HANDLER_MAX="100"
JENKINS_HANDLER_IDLE="20"
JENKINS_EXTRA_LIB_FOLDER=""
JENKINS_ARGS=" --prefix="
if [ -f /etc/sysconfig/jenkins ] ; then
  source /etc/sysconfig/jenkins
fi

PARAMS="--logfile=/var/log/jenkins/jenkins.log --webroot=/var/cache/jenkins/war"
[ -n "$JENKINS_PORT" ] && PARAMS="$PARAMS --httpPort=$JENKINS_PORT"
[ -n "$JENKINS_LISTEN_ADDRESS" ] && PARAMS="$PARAMS --httpListenAddress=$JENKINS_LISTEN_ADDRESS"
[ -n "$JENKINS_HTTPS_PORT" ] && PARAMS="$PARAMS --httpsPort=$JENKINS_HTTPS_PORT"
[ -n "$JENKINS_HTTPS_KEYSTORE" ] && PARAMS="$PARAMS --httpsKeyStore='$JENKINS_HTTPS_KEYSTORE'"
[ -n "$JENKINS_HTTPS_KEYSTORE_PASSWORD" ] && PARAMS="$PARAMS --httpsKeyStorePassword='$JENKINS_HTTPS_KEYSTORE_PASSWORD'"
[ -n "$JENKINS_HTTPS_LISTEN_ADDRESS" ] && PARAMS="$PARAMS --httpsListenAddress=$JENKINS_HTTPS_LISTEN_ADDRESS"
[ -n "$JENKINS_HTTP2_PORT" ] && PARAMS="$PARAMS --http2Port=$JENKINS_HTTP2_PORT"
[ -n "$JENKINS_HTTP2_LISTEN_ADDRESS" ] && PARAMS="$PARAMS --http2ListenAddress=$JENKINS_HTTP2_LISTEN_ADDRESS"
[ -n "$JENKINS_DEBUG_LEVEL" ] && PARAMS="$PARAMS --debug=$JENKINS_DEBUG_LEVEL"
[ -n "$JENKINS_HANDLER_STARTUP" ] && PARAMS="$PARAMS --handlerCountStartup=$JENKINS_HANDLER_STARTUP"
[ -n "$JENKINS_HANDLER_MAX" ] && PARAMS="$PARAMS --handlerCountMax=$JENKINS_HANDLER_MAX"
[ -n "$JENKINS_HANDLER_IDLE" ] && PARAMS="$PARAMS --handlerCountMaxIdle=$JENKINS_HANDLER_IDLE"
[ -n "$JENKINS_EXTRA_LIB_FOLDER" ] && PARAMS="$PARAMS --extraLibFolder='$JENKINS_EXTRA_LIB_FOLDER'"
[ -n "$JENKINS_ARGS" ] && PARAMS="$PARAMS $JENKINS_ARGS"

if [ "$JENKINS_ENABLE_ACCESS_LOG" = "yes" ]; then
    PARAMS="$PARAMS --accessLoggerClassName=winstone.accesslog.SimpleAccessLogger --simpleAccessLogger.format=combined --simpleAccessLogger.file=/var/log/jenkins/access_log"
fi

JENKINS_JAVA_CMD=/usr/bin/java
JENKINS_WAR="/usr/lib/jenkins/jenkins.war"

${JENKINS_JAVA_CMD} ${JENKINS_JAVA_OPTIONS} -DJENKINS_HOME=${JENKINS_HOME} -jar ${JENKINS_WAR} ${PARAMS}
