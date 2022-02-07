#!/bin/bash
set -o nounset
set -o errexit

set -x
[ -z ${PRPL_MAKE_JOBS:-} ] && PRPL_MAKE_JOBS=1


echo "------------------------------- prpl ------------------------------------------------------"
sudo -S sh -c "export LD_LIBRARY_PATH=.:/opt/prpl/bin:/opt/prpl/lib:/lib64:/lib:/usr/lib64/:/usr/lib:/usr/local/lib64:/usr/local/lib \
 && cd /opt/prpl \
 && git init \
 && git remote add origin https://github.com/davidcallen/parkrunpointsleague \
 && git fetch \
 && git checkout origin/master -ft \
 && cd src \
 && ./build.sh -clean -cpu ${PRPL_MAKE_JOBS}"

sudo -S sh -c 'chown -R prpl:prpl /opt/prpl'

ls -la /opt/prpl/*

sudo -S sh -c 'echo "LD_LIBRARY_PATH=.:/opt/prpl/bin:/opt/prpl/lib:/lib64:/lib:/usr/lib64/:/usr/lib:/usr/local/lib64:/usr/local/lib" > /etc/sysconfig/prpld'

sudo -S sh -c 'cp /opt/prpl/doc/prpld.service /usr/lib/systemd/system/ \
 && systemctl daemon-reload \
 && sudo systemctl enable prpld'

