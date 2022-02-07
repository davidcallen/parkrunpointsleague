#!/bin/bash
set -o nounset
set -o errexit

set -x
[ -z ${PRPL_MAKE_JOBS:-} ] && PRPL_MAKE_JOBS=1

sudo yum install -y gcc gcc-c++ gdb git cmake mariadb mariadb-devel openssl-devel libtool libtool-ltdl-devel

sudo useradd -G wheel prpl

sudo mkdir -p /opt

sudo mkdir -p /opt/prpl

# sudo echo "export LD_LIBRARY_PATH=.:/opt/prpl/src/../bin:/lib64:/lib:/usr/lib64/:/usr/lib:/usr/local/lib64:/usr/local/lib" >> /home/prpl/.bashrc

sudo mkdir -p /tmp/prpl-srcs/

echo "------------------------------- tidy-html ------------------------------------------------------"
sudo -S sh -c "export LD_LIBRARY_PATH=.:/opt/prpl/src/../bin:/lib64:/lib:/usr/lib64/:/usr/lib:/usr/local/lib64:/usr/local/lib \
 && cd /tmp/prpl-srcs \
 && git clone https://github.com/htacg/tidy-html5 \
 && cd tidy-html5 \
 && cd build/cmake \
 && cmake ../.. -DCMAKE_INSTALL_PREFIX=/opt/prpl -DCMAKE_BUILD_TYPE=Release \
 && make install"

echo "------------------------------- gumbo ------------------------------------------------------"
sudo -S sh -c "export LD_LIBRARY_PATH=.:/opt/prpl/src/../bin:/lib64:/lib:/usr/lib64/:/usr/lib:/usr/local/lib64:/usr/local/lib \
 && cd /tmp/prpl-srcs \
 && git clone https://github.com/google/gumbo-parser \
 && cd gumbo-parser \
 && ./autogen.sh \
 && ./configure --prefix=/opt/prpl \
 && make -j ${PRPL_MAKE_JOBS} \
 && make install"


echo "------------------------------- poco ------------------------------------------------------"
sudo -S sh -c "export LD_LIBRARY_PATH=.:/opt/prpl/src/../bin:/lib64:/lib:/usr/lib64/:/usr/lib:/usr/local/lib64:/usr/local/lib \
 && cd /tmp/prpl-srcs \
 && git clone -b poco-1.7.8 https://github.com/pocoproject/poco.git \
 && cd poco \
 && ./configure --prefix=/opt/prpl --everything --omit=Data/ODBC,Data/SQLite,PDF,MongoDB,ApacheConnector,CppParser,PageCompiler,ProGen,SevenZip --no-samples --no-tests \
 && mkdir cmake_build \
 && cd cmake_build \
 && cmake .. -DCMAKE_INSTALL_PREFIX=/opt/prpl -DENABLE_DATA_ODBC=OFF -DENABLE_DATA_SQLITE=OFF -DENABLE_PDF=OFF -DENABLE_TESTS=OFF -DENABLE_MONGODB=OFF -DENABLE_ZIP=OFF \
 && make -j ${PRPL_MAKE_JOBS} VERBOSE=1 \
 && make install"

sudo -S sh -c 'chown -R prpl:prpl /opt/prpl'

ls -la /opt/prpl/*
