#!/bin/bash
# Author: pblaas (patrick@kite4fun.nl)

# This script is used to generate a kubernetes user certificate files for RBAC enabled cluster.

if [ ! -f set/ca.pem ]; then
	echo set/ca.pem not found.
        echo Create a cluster certificate set first.
	exit 1

fi

if [ ! $1 ]; then
	echo Use following syntax:
	echo Syntax: $0 [USERNAME] [DEFAULT-NAMESPACE]
	exit 1
fi


#creating new user certificate.

if [ ! -f config.env ]; then
	echo config.env not found.
        echo cp config.env.sample to config.env and run the create_cloudinit.sh script. 
	exit 1
fi
. config.env

#create demouser certs
openssl genrsa -out set/$1-key.pem 2048
openssl req -new -key set/$1-key.pem -out set/$1.csr -subj "/CN=$1"
openssl x509 -req -in set/$1.csr -CA set/ca.pem -CAkey set/ca-key.pem -CAcreateserial -out set/$1.pem -days 365

echo "Configure the user with the following settings:"
echo ""
echo "kubectl config set-cluster $MASTER_HOST_IP-cluster --server=https://$MASTER_HOST_IP --certificate-authority=./set/ca.pem"
echo "kubectl config set-credentials $MASTER_HOST_IP-$1 --certificate-authority=./set/ca.pem --client-key=./set/$1-key.pem --client-certificate=./set/$1.pem"
echo "kubectl config set-context $MASTER_HOST_IP-$1 --cluster=$MASTER_HOST_IP-cluster --user=$MASTER_HOST_IP-$1 --namespace=$2"
echo "kubectl config use-context $MASTER_HOST_IP-$1"
echo ""
