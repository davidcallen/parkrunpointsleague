#!/bin/bash
# Build all packer images, sequentially in the correct dependancy order.
set -o errexit
set -o nounset

START_PATH=$(pwd)

# build in dependancy order
BUILD_DIRS=(centos-7-base \
centos-7-jenkins-controller \
centos-7-jenkins-worker-prpl-builder \
centos-7-nexus \
)

for DIR in "${BUILD_DIRS[@]}" ; do
  if [ ! -d ${DIR} ] ; then
    echo "ERROR : cannot find packer directory ${DIR}"
    continue
  fi
  cd ${DIR}
  echo
  echo "=========================================== Building : $DIR ============================================="
  echo
  ./packer-build-image.sh
  cd ${START_PATH}
done

echo "Finished all builds"
