FROM prpl-base:20190616085358

ADD ./DOCKER_IMAGE_TAG /

WORKDIR /prpl

RUN apk add --no-cache git gcc g++ binutils make cmake autoconf2.13 mariadb mariadb-client mariadb-dev openssl-dev libtool libltdl xmlstarlet

RUN cd /prpl
# Get source from GitHub
# RUN git clone https://github.com/davidcallen/parkrunpointsleague.git .
# Use local sources zip file
ADD prpl.srcs.tar.gz /
# Debug : Check files
RUN pwd && ls -la

RUN cd /prpl/src && export LD_LIBRARY_PATH=/lib64:/usr/lib64:/usr/local/lib64:/lib:/usr/lib:/usr/local/lib && ./build.sh -clean -cpu 2

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh  \
	&& sed -i -e 's/\r$//' /entrypoint.sh

CMD ["/entrypoint.sh"]
