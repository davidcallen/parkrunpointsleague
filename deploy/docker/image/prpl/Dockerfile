FROM <<PRPL_DOCKER_REGISTRY>>prpl-base:<<PRPL_BASE_DOCKER_IMAGE_TAG>>

# Input args :
ARG PRPL_USE_LOCAL_SOURCES
ARG PRPL_MAKE_JOBS
RUN echo "Input arg PRPL_USE_LOCAL_SOURCES=${PRPL_USE_LOCAL_SOURCES}"
RUN echo "Input arg PRPL_MAKE_JOBS=${PRPL_MAKE_JOBS}"

ADD ./DOCKER_IMAGE_TAG /

RUN apk --update add --no-cache git gcc g++ binutils make cmake autoconf2.13 mariadb mariadb-client mariadb-dev openssl-dev libtool libltdl xmlstarlet

RUN cd / && rm -rf /prpl

# Either :
#   1) Get source from GitHub
RUN if [ "${PRPL_USE_LOCAL_SOURCES}" == "FALSE" ] ; then git clone https://github.com/davidcallen/parkrunpointsleague.git /prpl ; fi
#   2) Use local sources zip file
<<COMMENT_OUT_IF_NOT_USE_LOCAL_SOURCES>> ADD prpl.srcs.tar.gz /

# Debug : Check files
RUN pwd && ls -la
RUN cd /prpl && pwd && ls -la

WORKDIR /prpl

RUN cd /prpl/src && export LD_LIBRARY_PATH=/lib64:/usr/lib64:/usr/local/lib64:/lib:/usr/lib:/usr/local/lib && ./build.sh -clean -cpu ${PRPL_MAKE_JOBS} && rm -rf /prpl/src/exe/prpld/CMakeFiles && rm -f /prpl/sql/db-backups/*

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh  \
	&& sed -i -e 's/\r$//' /entrypoint.sh

CMD ["/entrypoint.sh"]
