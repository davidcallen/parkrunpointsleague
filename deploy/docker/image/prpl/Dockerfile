FROM prpl-base:<<PRPL_BASE_DOCKER_IMAGE_TAG>>

ADD ./DOCKER_IMAGE_TAG /

RUN apk add --no-cache git gcc g++ binutils make cmake autoconf2.13 mariadb mariadb-client mariadb-dev openssl-dev libtool libltdl xmlstarlet

RUN cd / && rm -rf /prpl
# Get source from GitHub
<<COMMENT_OUT_IF_USE_LOCAL_SOURCES>>RUN git clone https://github.com/davidcallen/parkrunpointsleague.git /prpl
# Use local sources zip file
<<COMMENT_OUT_IF_NOT_USE_LOCAL_SOURCES>>ADD prpl.srcs.tar.gz /
# Debug : Check files
RUN pwd && ls -la
RUN cd /prpl && pwd && ls -la

WORKDIR /prpl

RUN cd /prpl/src && export LD_LIBRARY_PATH=/lib64:/usr/lib64:/usr/local/lib64:/lib:/usr/lib:/usr/local/lib && ./build.sh -clean -cpu <<PRPL_MAKE_JOBS>>

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh  \
	&& sed -i -e 's/\r$//' /entrypoint.sh

CMD ["/entrypoint.sh"]
