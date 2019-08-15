#!/bin/bash
set -o nounset
set -o errexit

set -x
[ -z ${PRPL_MAKE_JOBS:-} ] && PRPL_MAKE_JOBS=1


echo "------------------------------- prpl ------------------------------------------------------"
sudo -S sh -c "export LD_LIBRARY_PATH=.:/opt/prpl/src/../bin:/lib64:/lib:/usr/lib64/:/usr/lib:/usr/local/lib64:/usr/local/lib \
 && cd /opt/prpl \
 && git init \
 && git remote add origin https://github.com/davidcallen/parkrunpointsleague \
 && git fetch \
 && git checkout origin/master -ft \
 && cd src \
 && ./build.sh -clean -cpu ${PRPL_MAKE_JOBS}"

sudo -S sh -c 'chown prpl:prpl /opt/prpl'

sudo -S sh -c 'cp /opt/prpl/doc/prpld.service /usr/lib/systemd/system/ \
 && systemctl daemon-reload \
 && sudo systemctl status prpld \
 && sudo systemctl enable prpld'
