FROM alpine:latest

COPY ./DOCKER_IMAGE_TAG /

WORKDIR /prpl-libs

ADD build-output/lib/ /prpl-libs/lib/
ADD build-output/include/ /prpl-libs/include/

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh  \
	&& sed -i -e 's/\r$//' /entrypoint.sh

CMD ["/entrypoint.sh"]
