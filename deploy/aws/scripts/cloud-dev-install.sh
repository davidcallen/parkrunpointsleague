#!/bin/bash
#  Install cloud development tools
#     packer
#     terraform
#     kubectl, eksctl, helm
#     unzip, emacs, git
#
# This should work on CentOS7, Fedora, Ubunbtu, and Windows
# Tools like terraform are installed into your ~/bin
# They are labelled with their version to allow for mixed environments e.g. terraform-v1.0.11
set -o errexit
set -o nounset
START_PATH=$PWD
TEMP_DIR=

function err()
{
  echo  "ERROR in $0"
  [ -d ${TEMP_DIR} ] && rm -rf ${TEMP_DIR}
  cd ${START_PATH}
  exit 1
}
trap err ERR

OS_NAME=linux
# Check if $OS is set (should be on Windows but not in Linux)
if [ ! -z "${OS:-}" ] ; then
  [[ $OS =~ 'Win' ]] && OS_NAME=windows
fi
if [ "${OS_NAME}" == "linux" ] ; then
  if [ -e /etc/os-release ] ; then
    source /etc/os-release
    OS_LINUX_DISTRO=${ID}
  else
    OS_LINUX_DISTRO=$(lsb_release --id --short)
  fi
fi


HELM_VERSION=v3.7.1

# TODO : convert this script to ansible ...

if [ "${OS_NAME}" == "linux" ] ; then
  echo
  if [ "${OS_LINUX_DISTRO}" == "ubuntu" ] ; then
    sudo apt-get install -y unzip wget curl emacs-nox git ansible yubikey-manager pass
  else
    ANSIBLE_PACKAGE_NAME=ansible
    YUBIKEY_MANAGER_PACKAGE_NAME=
    KEYRING_NAME=gnome-keyring
    if [ "${ID}" == "centos" -a "${VERSION_ID}" == "7" ] ; then
      ANSIBLE_PACKAGE_NAME=centos-release-ansible-29
      YUBIKEY_MANAGER_PACKAGE_NAME=yubikey-manager
      KEYRING_NAME=pass
    elif [ "${ID}" == "centos" -a "${VERSION_ID}" == "8" ] ; then
      ANSIBLE_PACKAGE_NAME=centos-release-ansible-29
      YUBIKEY_MANAGER_PACKAGE_NAME=yubikey-manager
      KEYRING_NAME=pass
      # Install EPEL repo for pass and yubikey-manager
      sudo yum install -y https://download-ib01.fedoraproject.org/pub/epel/8/Everything/x86_64/Packages/e/epel-release-8-11.el8.noarch.rpm
    fi
    sudo yum install -y unzip wget curl emacs-nox git usbutils ${ANSIBLE_PACKAGE_NAME} ${YUBIKEY_MANAGER_PACKAGE_NAME} ${KEYRING_NAME}
  fi
  echo
fi

# Create temp download dir
TEMP_DIR=$(mktemp --directory --suffix=cloud-dev-install)
cd ${TEMP_DIR}


# ------------------------------------------  aws-vault   -------------------------------------------------------
# aws-vault by 99designs - used for handling aws credentials
INSTALL_AWS_VAULT=false
AWS_VAULT_VERSION=6.3.1
AWS_VAULT_EXE_FILENAME=aws-vault
[ "${OS_NAME}" == "windows" ] && AWS_VAULT_EXE_FILENAME=aws-vault.exe
if [ ! -f ~/bin/${AWS_VAULT_EXE_FILENAME} ] ; then
  INSTALL_AWS_VAULT=true
  echo "Installing aws-vault..."
else
  INSTALLED_AWS_VAULT_VERSION=$(~/bin/${AWS_VAULT_EXE_FILENAME} --version 2>&1)
  if [ "${INSTALLED_AWS_VAULT_VERSION}" != "v${AWS_VAULT_VERSION}" ] ; then
    echo "Upgrading aws-vault ${INSTALLED_AWS_VAULT_VERSION} -> ${AWS_VAULT_VERSION} ..."
    INSTALL_AWS_VAULT=true
  fi
fi
if [ ${INSTALL_AWS_VAULT} == true ] ; then
  echo
  [ ! -d ~/bin ] && mkdir ~/bin
  if [ "${OS_NAME}" == "linux" ] ; then
    curl  --silent --location -O https://github.com/99designs/aws-vault/releases/download/v${AWS_VAULT_VERSION}/aws-vault-linux-amd64
    mv aws-vault-linux-amd64 ~/bin/${AWS_VAULT_EXE_FILENAME}
    chmod +x ~/bin/${AWS_VAULT_EXE_FILENAME}
  else
    curl  --silent --location -O https://github.com/99designs/aws-vault/releases/download/v${AWS_VAULT_VERSION}/aws-vault-windows-386.exe
    mv aws-vault-windows-386.exe ~/bin/${AWS_VAULT_EXE_FILENAME}
  fi
fi

# ------------------------------------------  Packer  -------------------------------------------------------
INSTALL_PACKER=false
PACKER_VERSION=1.7.8
if [ ! -f ~/bin/packer ] ; then
  INSTALL_PACKER=true
  echo "Installing packer..."
else
  INSTALLED_PACKER_VERSION=$(~/bin/packer --version)
  if [ "${INSTALLED_PACKER_VERSION}" != "${PACKER_VERSION}" ] ; then
    echo "Upgrading packer ${INSTALLED_PACKER_VERSION} -> ${PACKER_VERSION} ..."
    INSTALL_PACKER=true
  fi
fi
if [ ${INSTALL_PACKER} == true ] ; then
  echo
  curl --silent --fail --remote-name https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_${OS_NAME}_amd64.zip
  unzip packer_${PACKER_VERSION}_${OS_NAME}_amd64.zip
  [ ! -d ~/bin ] && mkdir ~/bin
  mv packer ~/bin/
  chmod +x ~/bin/packer
  rm packer_${PACKER_VERSION}_${OS_NAME}_amd64.zip
fi

# ------------------------------------------  Terraform v0.15.4  -------------------------------------------------------
TERRAFORM_VERSIONS=(0.15.4 1.0.11)
for TERRAFORM_VERSION in "${TERRAFORM_VERSIONS[@]}" ; do
  INSTALL_TERRAFORM=false
  if [ ! -f ~/bin/terraform-v${TERRAFORM_VERSION} ] ; then
    INSTALL_TERRAFORM=true
    echo "Installing terraform..."
  else
    INSTALLED_TERRAFORM_VERSION=$(~/bin/terraform-v${TERRAFORM_VERSION} version | grep -o 'v[0-9].*\.[0-9].*\.[0-9].*')
    if [ "${INSTALLED_TERRAFORM_VERSION}" != "v${TERRAFORM_VERSION}" ] ; then
      echo "Upgrading terraform ${INSTALLED_TERRAFORM_VERSION} -> v${TERRAFORM_VERSION} ..."
      INSTALL_TERRAFORM=true
    fi
  fi
  if [ ${INSTALL_TERRAFORM} == true ] ; then
    echo
    curl --silent --fail --remote-name https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${OS_NAME}_amd64.zip
    unzip terraform_${TERRAFORM_VERSION}_${OS_NAME}_amd64.zip
    [ ! -d ~/bin ] && mkdir ~/bin
    mv terraform ~/bin/terraform-v${TERRAFORM_VERSION}
    chmod +x ~/bin/terraform-v${TERRAFORM_VERSION}
    rm terraform_${TERRAFORM_VERSION}_${OS_NAME}_amd64.zip
  fi
done

# ------------------------------------------  eksctl  -------------------------------------------------------
# TODO : add eksctl install
EKSCTL_VERSION=0.75.0
INSTALL_EKSCTL=false
if [ ! -f ~/bin/eksctl ] ; then
  INSTALL_EKSCTL=true
  echo "Installing eksctl..."
else
  INSTALLED_EKSCTL_VERSION=$(~/bin/eksctl version)
  if [ "${INSTALLED_EKSCTL_VERSION}" != "${EKSCTL_VERSION}" ] ; then
    echo "Upgrading eksctl ${INSTALLED_EKSCTL_VERSION} -> ${EKSCTL_VERSION} ..."
    INSTALL_EKSCTL=true
  fi
fi
if [ ${INSTALL_EKSCTL} == true ] ; then
  echo
  if [ "${OS_NAME}" == "windows" ] ; then
    curl --silent --fail --location --remote-name "https://github.com/weaveworks/eksctl/releases/download/v${EKSCTL_VERSION}/eksctl_Windows_amd64.zip"
    unzip -d /tmp eksctl_Windows_amd64.zip
  else
    curl --silent --fail --location --remote-name "https://github.com/weaveworks/eksctl/releases/download/v${EKSCTL_VERSION}/eksctl_$(uname -s)_amd64.tar.gz"
    tar xzf "eksctl_$(uname -s)_amd64.tar.gz"
  fi
  [ ! -d ~/bin ] && mkdir ~/bin
  mv eksctl ~/bin/
  chmod +x ~/bin/eksctl
fi

# ------------------------------------------  kubectl  -------------------------------------------------------
# Kubectl for kubernetes cluster v1.22
KUBECTL_VERSION=1.21.2
INSTALL_KUBECTL=false
if [ ! -f ~/bin/kubectl-v${KUBECTL_VERSION} ] ; then
  INSTALL_KUBECTL=true
  echo "Installing kubectl v${KUBECTL_VERSION}..."
else
  INSTALLED_KUBECTL_VERSION=$(~/bin/kubectl-v${KUBECTL_VERSION} version --short --client=true | grep -o -E 'v[0-9]+\.[0-9]+\.[0-9]+')
  if [ "${INSTALLED_KUBECTL_VERSION}" != "v${KUBECTL_VERSION}" ] ; then
    echo "Upgrading kubectl ${INSTALLED_KUBECTL_VERSION} -> v${KUBECTL_VERSION} ..."
    INSTALL_KUBECTL=true
  fi
fi
if [ ${INSTALL_KUBECTL} == true ] ; then
  echo
  if [ "${OS_NAME}" == "windows" ] ; then
    curl --silent --fail --remote-name https://amazon-eks.s3.us-west-2.amazonaws.com/${KUBECTL_VERSION}/2021-07-05/bin/${OS_NAME}/amd64/kubectl.exe
  else
    curl --silent --fail --remote-name https://amazon-eks.s3.us-west-2.amazonaws.com/${KUBECTL_VERSION}/2021-07-05/bin/${OS_NAME}/amd64/kubectl
  fi
  [ ! -d ~/bin ] && mkdir ~/bin
  mv kubectl ~/bin/kubectl-v${KUBECTL_VERSION}
  chmod +x ~/bin/kubectl-v${KUBECTL_VERSION}
fi

# ------------------------------------------  Helm  -------------------------------------------------------
# Helm for kubernetes
INSTALL_HELM=false
if [ ! -f ~/bin/helm ] ; then
  INSTALL_HELM=true
  echo "Installing Helm..."
else
  INSTALLED_HELM_VERSION=$(~/bin/helm version | grep -o -E 'v[0-9]+\.[0-9]+\.[0-9]+')
  if [ "${INSTALLED_HELM_VERSION}" != "${HELM_VERSION}" ] ; then
    echo "Upgrading Helm ${INSTALLED_HELM_VERSION} -> ${HELM_VERSION} ..."
    INSTALL_HELM=true
  fi
fi
if [ ${INSTALL_HELM} == true ] ; then
  echo
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
  chmod 700 get_helm.sh
  # Set HELM_INSTALL_DIR to for install to ~/bin instead of default of /usr/local/bin
  export HELM_INSTALL_DIR=~/bin
  ./get_helm.sh --no-sudo --version ${HELM_VERSION}
  rm -f ./get_helm.sh
fi

# ------------------------------------------  rancher  -------------------------------------------------------
# rancher for rancher cluster v1.22
RANCHER_VERSION=2.6.4
INSTALL_RANCHER=false
if [ ! -f ~/bin/rancher-v${RANCHER_VERSION} ] ; then
  INSTALL_RANCHER=true
  echo "Installing rancher v${RANCHER_VERSION}..."
else
  INSTALLED_RANCHER_VERSION=$(~/bin/rancher-v${RANCHER_VERSION} --version | grep -o -E 'v[0-9]+\.[0-9]+\.[0-9]+')
  if [ "${INSTALLED_RANCHER_VERSION}" != "v${RANCHER_VERSION}" ] ; then
    echo "Upgrading rancher ${INSTALLED_RANCHER_VERSION} -> v${RANCHER_VERSION} ..."
    INSTALL_RANCHER=true
  fi
fi
if [ ${INSTALL_RANCHER} == true ] ; then
  echo
  if [ "${OS_NAME}" == "windows" ] ; then
    curl --silent --fail --location --remote-name https://github.com/rancher/cli/releases/download/v${RANCHER_VERSION}/rancher-${OS_NAME}-amd64-v${RANCHER_VERSION}.zip
    unzip rancher-${OS_NAME}-amd64-v${RANCHER_VERSION}.zip
  else
    curl --silent --fail --location --remote-name https://github.com/rancher/cli/releases/download/v${RANCHER_VERSION}/rancher-${OS_NAME}-amd64-v${RANCHER_VERSION}.tar.xz
    tar xvf rancher-${OS_NAME}-amd64-v${RANCHER_VERSION}.tar.xz
  fi
  [ ! -d ~/bin ] && mkdir ~/bin
  mv ./rancher-v${RANCHER_VERSION}/rancher ~/bin/rancher-v${RANCHER_VERSION}
  chmod +x ~/bin/rancher-v${RANCHER_VERSION}
  ln -s ~/bin/rancher-v${RANCHER_VERSION} ~/bin/rancher
  rm -rf ./rancher
fi

# ------------------------------------------  sops  -------------------------------------------------------
# Mozilla sops for file decrypt+edit+encrypt
SOPS_VERSION=3.7.1
INSTALL_SOPS=false
if [ ! -f ~/bin/sops ] ; then
  INSTALL_SOPS=true
  echo "Installing SOPS..."
else
  # Note use head to ignore any following lines about upgrade to newer version
  INSTALLED_SOPS_VERSION=$(~/bin/sops --version | head -n 1 | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+')
  if [ "${INSTALLED_SOPS_VERSION}" != "${SOPS_VERSION}" ] ; then
    echo "Upgrading sops ${INSTALLED_SOPS_VERSION} -> ${SOPS_VERSION} ..."
    INSTALL_SOPS=true
  fi
fi
if [ ${INSTALL_SOPS} == true ] ; then
  echo
  curl  --silent --location -O https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux
  chmod +x sops-v${SOPS_VERSION}.linux
  mv sops-v${SOPS_VERSION}.linux ~/bin
  ln -s ~/bin/sops-v${SOPS_VERSION}.linux ~/bin/sops
fi

# ------------------------------------------  cmctl  -------------------------------------------------------
# Add download and install of cmctl for Cert-Manager
#
#OS=$(go env GOOS); ARCH=$(go env GOARCH); curl -sSL -o cmctl.tar.gz https://github.com/cert-manager/cert-manager/releases/download/v1.7.2/cmctl-$OS-$ARCH.tar.gz
#tar xzf cmctl.tar.gz
#sudo mv cmctl /usr/local/bin

# Cleanup
[ -d ${TEMP_DIR} ] && rm -rf ${TEMP_DIR}
cd ${START_PATH}

echo "Finished cloud-dev-install.sh : OK"
