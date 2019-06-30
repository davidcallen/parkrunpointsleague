FROM alpine:latest

COPY ./DOCKER_IMAGE_TAG /

WORKDIR /prpl

RUN apk add --no-cache git gcc g++ binutils make cmake autoconf2.13 \
	mariadb-client mariadb-connector-c mariadb-dev openssl-dev libtool libltdl \
	libtool automake autoconf file \
	linux-headers
