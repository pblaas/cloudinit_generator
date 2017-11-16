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

#create etcd CA
openssl genrsa -out etcd-ca-key.pem 2048
openssl req -x509 -new -nodes -key etcd-ca-key.pem -days 10000 -out etcd-ca.pem -subj "/CN=etcd-ca"


sed -e s/K8S_SERVICE_IP/$K8S_SERVICE_IP/ -e s/MASTER_HOST_IP/$MASTER_HOST_IP/ -e s/FLOATING_IP/$FLOATING_IP/ ../template/openssl.cnf > openssl.cnf

#create API certs
openssl genrsa -out apiserver-key.pem 2048
openssl req -new -key apiserver-key.pem -out apiserver.csr -subj "/CN=system:node:${MASTER_HOST_IP}" -config openssl.cnf
openssl x509 -req -in apiserver.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out apiserver.pem -days 365 -extensions v3_req -extfile openssl.cnf

#create ETCD-API-certs
openssl genrsa -out etcd-apiserver-key.pem 2048
openssl req -new -key etcd-apiserver-key.pem -out etcd-apiserver.csr -subj "/CN=etcd-kube-apiserver" -config openssl.cnf
openssl x509 -req -in etcd-apiserver.csr -CA etcd-ca.pem -CAkey etcd-ca-key.pem -CAcreateserial -out etcd-apiserver.pem -days 365 -extensions v3_req -extfile openssl.cnf

#create worker certs
for i in ${WORKER_HOSTS[@]}; do
openssl genrsa -out ${i}-worker-key.pem 2048
WORKER_IP=${i} openssl req -new -key ${i}-worker-key.pem -out ${i}-worker.csr -subj "/CN=system:node:${i}" -config ../template/worker-openssl.cnf
WORKER_IP=${i} openssl x509 -req -in ${i}-worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out ${i}-worker.pem -days 365 -extensions v3_req -extfile ../template/worker-openssl.cnf
done

#create ETCD-worker certs
for i in ${WORKER_HOSTS[@]}; do
openssl genrsa -out ${i}-etcd-worker-key.pem 2048
WORKER_IP=${i} openssl req -new -key ${i}-etcd-worker-key.pem -out ${i}-etcd-worker.csr -subj "/CN=${i}" -config ../template/worker-openssl.cnf
WORKER_IP=${i} openssl x509 -req -in ${i}-etcd-worker.csr -CA etcd-ca.pem -CAkey etcd-ca-key.pem -CAcreateserial -out ${i}-etcd-worker.pem -days 365 -extensions v3_req -extfile ../template/worker-openssl.cnf
done


#create admin certs
openssl genrsa -out admin-key.pem 2048
openssl req -new -key admin-key.pem -out admin.csr -subj "/CN=cluster-admin:kubeadmin"
openssl x509 -req -in admin.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out admin.pem -days 365

#create demouser certs
openssl genrsa -out demouser-key.pem 2048
openssl req -new -key demouser-key.pem -out demouser.csr -subj "/CN=cluster-admin:demouser"
openssl x509 -req -in demouser.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out demouser.pem -days 365

# encode to base64 gzip files.
# cat ca.pem | gzip | base64 -w0
# decode from base64 gzip string
# echo '<encoded-string> | base64 -di | zcat

#gzip base64 encode files to store in the cloud init files.
CAKEY=$(cat ca-key.pem | gzip | base64 -w0)
CACERT=$(cat ca.pem | gzip | base64 -w0)
ETCDCAKEY=$(cat etcd-ca-key.pem | gzip | base64 -w0)
ETCDCACERT=$(cat etcd-ca.pem | gzip | base64 -w0)
ETCDCACERT_BASE64=$(cat etcd-ca.pem | base64 -w0)
APISERVERKEY=$(cat apiserver-key.pem | gzip | base64 -w0)
APISERVER=$(cat apiserver.pem | gzip | base64 -w0)
ETCDAPISERVERKEY=$(cat etcd-apiserver-key.pem | gzip | base64 -w0)
ETCDAPISERVER=$(cat etcd-apiserver.pem | gzip | base64 -w0)

ETCDCACERTBASE64=$(cat etcd-ca.pem | base64 -w0)
ETCDAPISERVERKEYBASE64=$(cat etcd-apiserver-key.pem | base64 -w0)
ETCDAPISERVERBASE64=$(cat etcd-apiserver.pem | base64 -w0)

for i in ${WORKER_HOSTS[@]}; do
	j=$i-worker-key.pem
	k=$i-worker.pem
	l=$i-etcd-worker-key.pem
	m=$i-etcd-worker.pem
	WORKERKEY=$(cat $j | gzip | base64 -w0)
	WORKER=$(cat $k | gzip | base64 -w0)
	ETCDWORKERKEY=$(cat $l | gzip | base64 -w0)
	ETCDWORKER=$(cat $m | gzip | base64 -w0)
	ETCDWORKERKEYBASE64=$(cat $l | base64 -w0)
	ETCDWORKERBASE64=$(cat $m | base64 -w0)
	echo WORKERKEY_$i:$WORKERKEY >> index.txt
	echo WORKER_$i:$WORKER >> index.txt
	echo ETCDWORKERKEY_$i:$ETCDWORKERKEY >> index.txt
	echo ETCDWORKER_$i:$ETCDWORKER >> index.txt
	echo ETCDWORKERKEYBASE64_$i:$ETCDWORKERKEYBASE64 >> index.txt
	echo ETCDWORKERBASE64_$i:$ETCDWORKERBASE64 >> index.txt
done

ADMINKEY=`cat admin-key.pem | gzip | base64 -w0`
ADMIN=`cat admin.pem | gzip | base64 -w0`
CLOUDCONF=`cat ../../cloud.conf | gzip | base64 -w0`

#create indexfile with hashes
echo CAKEY:$CAKEY >> index.txt
echo CACERT:$CACERT >> index.txt
echo ETCDCAKEY:$ETCDCAKEY >> index.txt
echo ETCDCACERT:$ETCDCACERT >> index.txt
echo ETCDCACERTBASE64:$ETCDCACERTBASE64 >> index.txt
echo APISERVERKEY:$APISERVERKEY >> index.txt
echo APISERVER:$APISERVER >> index.txt
echo ADMINKEY:$ADMINKEY >> index.txt
echo ADMIN:$ADMIN >> index.txt
echo CLOUDCONF:$CLOUDCONF >> index.txt

#convert ssh public key to base64 gzip.
UCK1=`echo $USER_CORE_KEY1 | gzip | base64 -w0`

if [ $NET_OVERLAY == "calico" ]; then
	NETOVERLAY_MOUNTS="--volume cni-net,kind=host,source=/etc/cni/net.d \\\\\n        --mount volume=cni-net,target=/etc/cni/net.d \\\\\n        --volume cni-bin,kind=host,source=/opt/cni/bin \\\\\n        --mount volume=cni-bin,target=/opt/cni/bin \\\\"
	NETOVERLAY_DIRS="ExecStartPre=/usr/bin/mkdir -p /opt/cni/bin\n        ExecStartPre=/usr/bin/mkdir -p /etc/cni/net.d"
	NETOVERLAY_CNICONF="--cni-conf-dir=/etc/cni/net.d \\\\\n        --cni-bin-dir=/opt/cni/bin \\\\"
else
	NETOVERLAY_CNICONF="--cni-conf-dir=/etc/kubernetes/cni/net.d \\\\"
	NETOVERLAY_MOUNTS="\\\\"
	NETOVERLAY_DIRS="\\\\"
fi

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
-e "s,CLOUD_PROVIDER,${CLOUD_PROVIDER},g" \
-e "s,K8S_VER,$K8S_VER,g" \
-e "s,\<CACERT\>,$CACERT,g" \
-e "s,\<APISERVERKEY\>,$APISERVERKEY,g" \
-e "s,\<APISERVER\>,$APISERVER,g" \
-e "s,\<ETCDCACERT\>,$ETCDCACERT,g" \
-e "s,\<ETCDAPISERVERKEY\>,$ETCDAPISERVERKEY,g" \
-e "s,\<ETCDAPISERVER\>,$ETCDAPISERVER,g" \
-e "s,CLOUDCONF,$CLOUDCONF,g" \
-e "s,FLANNEL_VER,$FLANNEL_VER,g" \
-e "s@AUTHORIZATION_MODE@${AUTHORIZATION_MODE}@g" \
-e "s@NETOVERLAY_MOUNTS@${NETOVERLAY_MOUNTS}@g" \
-e "s@NETOVERLAY_DIRS@${NETOVERLAY_DIRS}@g" \
-e "s@NETOVERLAY_CNICONF@${NETOVERLAY_CNICONF}@g" \
../template/controller.yaml > node_$MASTER_HOST_IP.yaml
echo ----------------------
echo Generated: Master: node_$MASTER_HOST_IP.yaml


#genereate the worker yamls from the worker.yaml template
for i in ${WORKER_HOSTS[@]}; do
sed -e "s,WORKER_IP,$i,g" \
-e "s,DISCOVERY_ID,$DISCOVERY_ID,g" \
-e "s,WORKER_GW,$WORKER_GW,g" \
-e "s,DNSSERVER,$DNSSERVER,g" \
-e "s,MASTER_HOST_IP,$MASTER_HOST_IP,g" \
-e "s,CLUSTER_DNS,$CLUSTER_DNS,g" \
-e "s@ETCD_ENDPOINTS_URLS@${ETCD_ENDPOINTS_URLS}@g" \
-e "s,USER_CORE_SSHKEY1,${USER_CORE_KEY1}," \
-e "s,USER_CORE_SSHKEY2,${USER_CORE_KEY2}," \
-e "s,USER_CORE_PASSWORD,$HASHED_USER_CORE_PASSWORD,g" \
-e "s,CLOUD_PROVIDER,${CLOUD_PROVIDER},g" \
-e "s,K8S_VER,$K8S_VER,g" \
-e "s,\<CACERT\>,$CACERT,g" \
-e "s,\<WORKERKEY\>,`cat index.txt|grep -w WORKERKEY_$i|cut -d: -f2`,g" \
-e "s,\<WORKER\>,`cat index.txt|grep -w WORKER_$i|cut -d: -f2`,g" \
-e "s,\<ETCDCACERT\>,$ETCDCACERT,g" \
-e "s,\<ETCDWORKERKEY\>,`cat index.txt|grep -w ETCDWORKERKEY_$i|cut -d: -f2`,g" \
-e "s,\<ETCDWORKER\>,`cat index.txt|grep -w ETCDWORKER_$i|cut -d: -f2`,g" \
-e "s,CLOUDCONF,$CLOUDCONF,g" \
-e "s,FLANNEL_VER,$FLANNEL_VER,g" \
-e "s@NETOVERLAY_MOUNTS@${NETOVERLAY_MOUNTS}@g" \
-e "s@NETOVERLAY_DIRS@${NETOVERLAY_DIRS}@g" \
-e "s@NETOVERLAY_CNICONF@${NETOVERLAY_CNICONF}@g" \
../template/worker.yaml > node_$i.yaml
echo Generated: Worker: node_$i.yaml
done
echo ---------------------

sed -e "s,\<ETCDCACERTBASE64\>,$ETCDCACERTBASE64,g" \
-e "s,\<ETCDAPISERVERKEYBASE64\>,$ETCDAPISERVERKEYBASE64,g" \
-e "s,\<ETCDAPISERVERBASE64\>,$ETCDAPISERVERBASE64,g" \
-e "s@ETCD_ENDPOINTS_URLS@${ETCD_ENDPOINTS_URLS}@g" \
../template/calico.tmpl.yaml > calico.yaml
echo Generated: Calico.yaml
echo ---------------------
cp ../template/calico_ctl_tmpl.yaml calico_ctl.yaml
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
