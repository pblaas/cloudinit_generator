:exclamation: The scripts used in this project are outdated and will not work with the latest versions of CoreOS due to the fact the scripts are based on etcd2 which is no longer supported by later version of CoreOS. Besides the etcd version the scripts utilize the cloud init method for loading the config. I fixed both issues in other project https://github.com/pblaas/nagoya however primary use for this project is an OpenStack environment. 

This project will still receive some updates in the services section; however this will eventually be moved to the https://github.com/pblaas/k8services project.

## Cloudinit generator
This script and templates can be used to simplify deployment of a CoreOS Container Linux Kubernetes cluster. It contains 3 steps.

### Modify
Change the config.env with the required settings.

### Generate
Run the create_cloudinit.sh to generate the cloud init yaml files.

### Deploy
Deploy the cloud init files by serving the init yaml e.g through docker.

```
docker run -ti --rm -p 80:80 -v $PWD/set:/usr/share/nginx/html pblaas/nginx-alpine
```

After serving the files yaml files boot into CoreOS PXE or ISO and get the yaml and use it to install the system.

#### controller
```
curl http://dockerwebserver/node_IPMASTER.yaml > master.yaml && sudo coreos-install -d /dev/sda -c master.yaml
```
#### workers
```
curl http://dockerwebserver/node_IPADRESWORKER.yaml > node.yaml && sudo coreos-install -d /dev/sda -c node.yaml
```
After loading the yamls to the controller and the worker nodes umount the ISO and reboot the servers. You should now have a fully working Kubernetes cluster. Before continuing to the other good stuff test some commands on the cluster with the [testing section](#testing)


## Addons
1. DNS
```
kubectl create -f addons/dns-addon.yaml
```
2. Dashboard
```
kubectl create -f addons/kubernetes-dashboard.yaml
kubectl proxy
http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
```
3. Heapster && Influx && Grafana
  ```
  kubectl create -f addons/grafana-deployment.yaml
  kubectl create -f addons/grafana-service.yaml
  kubectl create -f addons/heapster-deployment.yaml
  kubectl create -f addons/heapster-service.yaml
  kubectl create -f addons/influxdb-deployment.yaml
  kubectl create -f addons/influxdb-service.yaml
  ```

To save yourself some time you could also install all the addons at once.
```
kubectl create -f addons/
```

## Loadbalancing
Loadbalancing with Traefik is added in the
[Loadbalacing](https://github.com/pblaas/cloudinit_generator/tree/master/loadbalancing) part of the repo.

## storage
HyperConverged storage with Heketi-glusterFS is added in the
[Storage](https://github.com/pblaas/cloudinit_generator/tree/master/storage) part of the repo.

### Troubleshooting
Interesting reads:
https://github.com/kubernetes/dashboard/blob/master/docs/user-guide/troubleshooting.md<br>
https://medium.com/@rothgar/exposing-services-using-ingress-with-on-prem-kubernetes-clusters-f413d87b6d34

### Vmware
If you are using CoreOS Container Linux on VMware you might want to use an additional unit file to spin up a VMware tools container.<br>
check out the following link for more info: https://hub.docker.com/r/godmodelabs/open-vm-tools/

### Testing
Check out the cluster state:
```
kubectl get cs
```
Check out the cluster nodes:
```
kubectl get nodes
```

Running a Nginx webserver on the new cluster:
```
kubectl run nginx --image=nginx --replicas=1 --port=80
kubectl expose deployment nginx --port=80 --type=NodePort
```

Grab the port from the nginx process<br>
```
kubectl get services|grep nginx|awk '{print $4}'|cut -c4-8
```
Browse to your <code>http://master_host:port</code>
