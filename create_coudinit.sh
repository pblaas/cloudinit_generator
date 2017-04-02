#!/bin/bash
# Author: pblaas
# Inital version 04-2017

# This script is used to generate Kubernetes cloud-image files for CoreoS.
# it could use some polish.

. config.env

#create new  discovery KEY
#Thank you for the service CoreOS.
DISCOVERY_ID=`curl -sB https://discovery.etcd.io/new?size=3|cut -d/ -f4`

echo This will DESTROY all files in the set directory. Continue? [No/YES]
read ANSWER

if [ $ANSWER == "YES" ]; then

if [ ! -d set ]; then
  mkdir set
fi

rm -vf set/*

#create root CA
cd set
openssl genrsa -out ca-key.pem 2048
openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=kube-ca"

sed -e s/K8S_SERVICE_IP/$K8S_SERVICE_IP/ -e s/MASTER_HOST/$MASTER_HOST_IP/ ../template/openssl.cnf > openssl.cnf

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

# encode to base64 gzip files.
# cat ca.pem | gzip | base64 -w0
# decode from base64 gzip string
# echo '<encoded-string> | base64 -di | zcat

#gzip base64 encode files to store in the cloud init files.
CAKEY=$(cat ca-key.pem | gzip | base64 -w0)
CA=$(cat ca.pem | gzip | base64 -w0)
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
echo CA:$CAKEY >> index.txt
echo APISERVERKEY:$APISERVERKEY >> index.txt
echo APISERVER:$APISERVER >> index.txt
echo ADMINKEY:$ADMINKEY >> index.txt
echo ADMIN:$ADMIN >> index.txt

#generate the master.yaml from the controller.yaml template
sed -e s,MASTER_HOST_FQDN,$MASTER_HOST_FQDN,g \
-e s,MASTER_HOST_IP,$MASTER_HOST_IP,g \
-e s,MASTER_HOST_GW,$MASTER_HOST_GW,g \
-e s,DISCOVERY_ID,$DISCOVERY_ID,g \
-e s,DNSSERVER,$DNSSERVER,g \
-e s,CLUSTER_DNS,$CLUSTER_DNS,g \
-e s@ETCD_ENDPOINTS_URLS@${ETCD_ENDPOINTS_URLS}@g \
-e s,SERVICE_CLUSTER_IP_RANGE,$SERVICE_CLUSTER_IP_RANGE,g \
-e s,CA,$CA,g \
-e s,APISERVERKEY,$APISERVERKEY,g \
-e s,APISERVER,$APISERVER,g \
../template/controller.yaml > master.yaml

#genereate the worker yamls from the worker.yaml template
for i in ${WORKER_HOSTS[@]}; do
sed -e s,WORKER_IP,$i,g \
-e s,DISCOVERY_ID,$DISCOVERY_ID,g \
-e s,WORKER_GW,$WORKER_GW,g \
-e s,DNSSERVER,$DNSSERVER,g \
-e s,MASTER_HOST,$MASTER_HOST_IP,g \
-e s,CLUSTER_DNS,$CLUSTER_DNS,g \
-e s@ETCD_ENDPOINTS_URLS@${ETCD_ENDPOINTS_URLS}@g \
-e s,CA,$CA,g \
-e s,WORKERKEY,`cat index.txt|grep WORKERKEY_$i|cut -d: -f2`,g \
-e s,WORKER,`cat index.txt|grep WORKER_$i|cut -d: -f2`,g \
../template/worker.yaml > worker_$i.yaml
echo worker: $i
done

cd -
else 
	echo Aborting.
fi

