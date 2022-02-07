#!/bin/bash
# See https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/cvpn-getting-started.html
#
#	Setup of Create Client and Server certificates on laptop using easy-rsa :
#		See https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/authentication-authorization.html#mutual
#		Using Certificate Mutual Authentication
set -o errexit
set -x

if [ ! -d ~/prpl-easy-rsa ] ; then
  git clone https://github.com/OpenVPN/easy-rsa.git ~/prpl-easy-rsa
  cd ~/prpl-easy-rsa/easyrsa3
  ./easyrsa init-pki
  export EASYRSA_BATCH=TRUE
  export EASYRSA_REQ_CN=parkrunpointsleague.org
  ./easyrsa build-ca nopass
  ./easyrsa build-server-full server nopass
  ./easyrsa build-client-full ${EASYRSA_REQ_CN} nopass
  # You can optionally repeat the above step for each client (end user) that requires a client certificate and key.

  # Copy the certs out for use by Linux Network Manager
  DESTINATION_VPN_CERTS_PATH=~/.cert/nm-openvpn
  [ ! -d ${DESTINATION_VPN_CERTS_PATH} ] && mkdir ${DESTINATION_VPN_CERTS_PATH}
  cp pki/ca.crt ${DESTINATION_VPN_CERTS_PATH}/prpl-client-vpn-ca.crt
  cp pki/issued/server.crt ${DESTINATION_VPN_CERTS_PATH}/prpl-client-vpn-server.crt
  cp pki/private/server.key ${DESTINATION_VPN_CERTS_PATH}/prpl-client-vpn-server.key
  cp pki/issued/${EASYRSA_REQ_CN}.crt ${DESTINATION_VPN_CERTS_PATH}/prpl-client-vpn-client.crt
  cp pki/private/${EASYRSA_REQ_CN}.key ${DESTINATION_VPN_CERTS_PATH}/prpl-client-vpn-client.key
else
  echo "ERROR : ~/prpl-easy-rsa already exists"
  exit 1
fi
