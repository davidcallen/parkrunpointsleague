FROM alpine:latest

COPY ./DOCKER_IMAGE_TAG /

WORKDIR /prpl-libs

ADD lib/ /prpl-libs/lib/
ADD include/ /prpl-libs/include/

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh  \
	&& sed -i -e 's/\r$//' /entrypoint.sh

CMD ["/entrypoint.sh"]
