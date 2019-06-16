FROM alpine:latest

COPY ./DOCKER_IMAGE_TAG /

WORKDIR /prpl

RUN apk add --no-cache git gcc g++ binutils make cmake autoconf2.13 mariadb mariadb-dev openssl-dev libtool libltdl 

# Get and build GUMBO
RUN apk add --no-cache libtool automake autoconf file
RUN cd /prpl/ \
	&& git clone https://github.com/google/gumbo-parser \
	&& cd gumbo-parser \
	&& ./autogen.sh \
	&& ./configure \
	&& make -j 2 \
	&& make install

# Get and build LIBTIDY
RUN mkdir /prpl/libtidy \
	&& cd /prpl/libtidy \
	&& git clone https://github.com/htacg/tidy-html5 \
	&& cd tidy-html5 \
	&& cd build/cmake \
	&& cmake ../.. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release \
	&& make install

# Get and build POCO
RUN apk add --no-cache linux-headers
RUN cd /prpl/ \
	&& export LD_LIBRARY_PATH=/lib64:/usr/lib64:/usr/local/lib64:/lib:/usr/lib:/usr/local/lib \
	&& git clone -b poco-1.7.8 https://github.com/pocoproject/poco.git \
	&& cd poco \
	&& ./configure --everything --omit=Data/ODBC,Data/SQLite,PDF,MongoDB,ApacheConnector,CppParser,PageCompiler,ProGen,SevenZip --no-samples --no-tests \
	&& make -j 2 \
	&& make install

# Now clean the sources...
RUN rm -rf /prpl/poco /prpl/gumbo-parser /prpl/libtidy/tidy-html5

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh  \
	&& sed -i -e 's/\r$//' /entrypoint.sh

CMD ["/entrypoint.sh"]
