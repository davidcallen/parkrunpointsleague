FROM alpine:latest

# Input args :
ARG PRPL_USE_LOCAL_SOURCES
ARG PRPL_MAKE_JOBS
RUN echo "Input arg PRPL_USE_LOCAL_SOURCES=${PRPL_USE_LOCAL_SOURCES}"
RUN echo "Input arg PRPL_MAKE_JOBS=${PRPL_MAKE_JOBS}"

ADD ./DOCKER_IMAGE_TAG /

RUN apk --update add --no-cache libgcc libstdc++ mariadb-client mariadb-connector-c xmlstarlet 

WORKDIR /prpl

ADD /build-output/bin/ /prpl/bin/
ADD /build-output/lib/ /prpl/lib/
ADD /build-output/assets/ /prpl/assets/
ADD /build-output/sql/ /prpl/sql/
ADD /build-output/doc/ /prpl/doc/

# Debug : Check files
RUN pwd && ls -la
RUN cd /prpl && pwd && ls -la

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh  \
	&& sed -i -e 's/\r$//' /entrypoint.sh

CMD ["/entrypoint.sh"]
