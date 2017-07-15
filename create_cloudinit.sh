#!/bin/bash
# Author: pblaas (patrick@kite4fun.nl)
# Initial version 04-2017

# This script is used to generate Kubernetes cloud-init files for CoreoS.

if [ ! -f config.env ]; then
	echo config.env not found.
        echo cp config.env.sample to config.env to get started.
	exit 1
fi
. config.env

echo This will DESTROY all files in the set directory. Continue? [No/YES]
read ANSWER

if [ $ANSWER == "YES" ]; then

if [ ! -d set ]; then
  mkdir set
fi

rm -vf set/*

#create new  discovery KEY
#Thank you for the service CoreOS team!
DISCOVERY_ID=`curl -sB https://discovery.etcd.io/new?size=3|cut -d/ -f4`
#DISCOVERY_ID="1234"


CUSTOMSALT=$(openssl rand -base64 14)
HASHED_USER_CORE_PASSWORD=$(perl -le "print crypt '$USER_CORE_PASSWORD', '\$6\$$CUSTOMSALT' ")

cd set
# Saving discovery ID for future worker use.
echo DISCOVERY_ID:$DISCOVERY_ID >> index.txt

#create root CA
openssl genrsa -out ca-key.pem 2048
openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=kube-ca"

sed -e s/K8S_SERVICE_IP/$K8S_SERVICE_IP/ -e s/MASTER_HOST_IP/$MASTER_HOST_IP/ -e s/FLOATING_IP/$FLOATING_IP/ ../template/openssl.cnf > openssl.cnf

#create API certs
openssl genrsa -out apiserver-key.pem 2048
openssl req -new -key apiserver-key.pem -out apiserver.csr -subj "/CN=kube-apiserver" -config openssl.cnf
openssl x509 -req -in apiserver.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out apiserver.pem -days 365 -extensions v3_req -extfile openssl.cnf

#create worker certs
for i in ${WORKER_HOSTS[@]}; do
openssl genrsa -out ${i}-worker-key.pem 2048
WORKER_IP=${i} openssl req -new -key ${i}-worker-key.pem -out ${i}-worker.csr -subj "/CN=${i}" -config ../template/worker-openssl.cnf
WORKER_IP=${i} openssl x509 -req -in ${i}-worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out ${i}-worker.pem -days 365 -extensions v3_req -extfile ../template/worker-openssl.cnf
done

#create admin certs
openssl genrsa -out admin-key.pem 2048
openssl req -new -key admin-key.pem -out admin.csr -subj "/CN=kube-admin"
openssl x509 -req -in admin.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out admin.pem -days 365

#create demouser certs
openssl genrsa -out demouser-key.pem 2048
openssl req -new -key demouser-key.pem -out demouser.csr -subj "/CN=demouser"
openssl x509 -req -in demouser.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out demouser.pem -days 365

# encode to base64 gzip files.
# cat ca.pem | gzip | base64 -w0
# decode from base64 gzip string
# echo '<encoded-string> | base64 -di | zcat

#gzip base64 encode files to store in the cloud init files.
CAKEY=$(cat ca-key.pem | gzip | base64 -w0)
CACERT=$(cat ca.pem | gzip | base64 -w0)
APISERVERKEY=$(cat apiserver-key.pem | gzip | base64 -w0)
APISERVER=$(cat apiserver.pem | gzip | base64 -w0)

for i in ${WORKER_HOSTS[@]}; do
	j=$i-worker-key.pem
	k=$i-worker.pem
	WORKERKEY=$(cat $j | gzip | base64 -w0)
	WORKER=$(cat $k | gzip | base64 -w0)
	echo WORKERKEY_$i:$WORKERKEY >> index.txt
	echo WORKER_$i:$WORKER >> index.txt
done

ADMINKEY=`cat admin-key.pem | gzip | base64 -w0`
ADMIN=`cat admin.pem | gzip | base64 -w0`

#create indexfile with hashes
echo CAKEY:$CAKEY >> index.txt
echo CACERT:$CACERT >> index.txt
echo APISERVERKEY:$APISERVERKEY >> index.txt
echo APISERVER:$APISERVER >> index.txt
echo ADMINKEY:$ADMINKEY >> index.txt
echo ADMIN:$ADMIN >> index.txt

#convert ssh public key to base64 gzip.
UCK1=`echo $USER_CORE_KEY1 | gzip | base64 -w0`

#generate the master.yaml from the controller.yaml template
sed -e "s,MASTER_HOST_FQDN,$MASTER_HOST_FQDN,g" \
-e "s,MASTER_HOST_IP,$MASTER_HOST_IP,g" \
-e "s,MASTER_HOST_GW,$MASTER_HOST_GW,g" \
-e "s,DISCOVERY_ID,$DISCOVERY_ID,g" \
-e "s,DNSSERVER,$DNSSERVER,g" \
-e "s,CLUSTER_DNS,$CLUSTER_DNS,g" \
-e "s@ETCD_ENDPOINTS_URLS@${ETCD_ENDPOINTS_URLS}@g" \
-e "s,SERVICE_CLUSTER_IP_RANGE,$SERVICE_CLUSTER_IP_RANGE,g" \
-e "s,USER_CORE_SSHKEY1,${USER_CORE_KEY1}," \
-e "s,USER_CORE_SSHKEY2,${USER_CORE_KEY2}," \
-e "s,USER_CORE_PASSWORD,$HASHED_USER_CORE_PASSWORD,g" \
-e "s,K8S_VER,$K8S_VER,g" \
-e "s,CACERT,$CACERT,g" \
-e "s,APISERVERKEY,$APISERVERKEY,g" \
-e "s,APISERVER,$APISERVER,g" \
../template/controller.yaml > node_$MASTER_HOST_IP.yaml
echo ----------------------
echo Generated: Master: node_$MASTER_HOST_IP.yaml

#genereate the worker yamls from the worker.yaml template
for i in ${WORKER_HOSTS[@]}; do
sed -e "s,WORKER_IP,$i,g" \
-e "s,DISCOVERY_ID,$DISCOVERY_ID,g" \
-e "s,WORKER_GW,$WORKER_GW,g" \
-e "s,DNSSERVER,$DNSSERVER,g" \
-e "s,MASTER_HOST,$MASTER_HOST_IP,g" \
-e "s,CLUSTER_DNS,$CLUSTER_DNS,g" \
-e "s@ETCD_ENDPOINTS_URLS@${ETCD_ENDPOINTS_URLS}@g" \
-e "s,USER_CORE_SSHKEY1,${USER_CORE_KEY1}," \
-e "s,USER_CORE_SSHKEY2,${USER_CORE_KEY2}," \
-e "s,USER_CORE_PASSWORD,$HASHED_USER_CORE_PASSWORD,g" \
-e "s,K8S_VER,$K8S_VER,g" \
-e "s,CACERT,$CACERT,g" \
-e "s,WORKERKEY,`cat index.txt|grep WORKERKEY_$i|cut -d: -f2`,g" \
-e "s,WORKER,`cat index.txt|grep WORKER_$i|cut -d: -f2`,g" \
../template/worker.yaml > node_$i.yaml
echo Generated: Worker: node_$i.yaml
done
echo -----------------------------------
cd -

echo You can run the following to interact with your new cluster:
echo ""
echo "kubectl config set-cluster $MASTER_HOST_IP-cluster --server=https://$MASTER_HOST_IP --certificate-authority=./set/ca.pem"
echo "kubectl config set-credentials $MASTER_HOST_IP-admin --certificate-authority=./set/ca.pem --client-key=./set/admin-key.pem --client-certificate=./set/admin.pem"
echo "kubectl config set-credentials $MASTER_HOST_IP-demouser --certificate-authority=./set/ca.pem --client-key=./set/demouser-key.pem --client-certificate=./set/demouser.pem"
echo "kubectl config set-context $MASTER_HOST_IP-admin --cluster=$MASTER_HOST_IP-cluster --user=$MASTER_HOST_IP-admin"
echo "kubectl config set-context $MASTER_HOST_IP-demouser --cluster=$MASTER_HOST_IP-cluster --user=$MASTER_HOST_IP-demouser"
echo "kubectl config use-context $MASTER_HOST_IP-admin"
echo "#OR"
echo "kubectl config use-context $MASTER_HOST_IP-demouser"
echo ""
else
	echo Aborting.
fi
