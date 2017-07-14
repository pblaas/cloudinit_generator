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

if [ ! $1 ]; then 
	echo You need to provide one or more ip adresses.
	echo e.g $0 192.168.10.12
	exit 1
fi

cd set

CUSTOMSALT=$(openssl rand -base64 14)
HASHED_USER_CORE_PASSWORD=$(perl -le "print crypt '$USER_CORE_PASSWORD', '\$6\$$CUSTOMSALT' ")

#create worker certs
for i in $1; do
openssl genrsa -out ${i}-worker-key.pem 2048
WORKER_IP=${i} openssl req -new -key ${i}-worker-key.pem -out ${i}-worker.csr -subj "/CN=${i}" -config ../template/worker-openssl.cnf
WORKER_IP=${i} openssl x509 -req -in ${i}-worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out ${i}-worker.pem -days 365 -extensions v3_req -extfile ../template/worker-openssl.cnf
done


#gzip base64 encode files to store in the cloud init files.
CAKEY=$(cat ca-key.pem | gzip | base64 -w0)
CACERT=$(cat ca.pem | gzip | base64 -w0)
APISERVERKEY=$(cat apiserver-key.pem | gzip | base64 -w0)
APISERVER=$(cat apiserver.pem | gzip | base64 -w0)

for i in $1; do
	j=$i-worker-key.pem
	k=$i-worker.pem
	WORKERKEY=$(cat $j | gzip | base64 -w0)
	WORKER=$(cat $k | gzip | base64 -w0)
	echo WORKERKEY_$i:$WORKERKEY >> index.txt
	echo WORKER_$i:$WORKER >> index.txt
done

#convert ssh public key to base64 gzip.
UCK1=`echo $USER_CORE_KEY1 | gzip | base64 -w0`

#genereate the worker yamls from the worker.yaml template
for i in $1; do
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
../template/worker_proxy.yaml > node_$i.yaml
echo Generated: node_$i.yaml
done
echo -----------------------------------
cd -
echo ""
