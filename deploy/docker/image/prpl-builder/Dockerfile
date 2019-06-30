FROM alpine:latest

# Input args
ARG PRPL_MAKE_JOBS
RUN echo "Input arg PRPL_MAKE_JOBS=${PRPL_MAKE_JOBS}"

COPY ./DOCKER_IMAGE_TAG /

WORKDIR /prpl

RUN apk add --no-cache git gcc g++ binutils make cmake autoconf2.13 \
	mariadb-client mariadb-connector-c mariadb-dev openssl-dev libtool libltdl \
	libtool automake autoconf file \
	linux-headers
