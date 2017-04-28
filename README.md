## Cloudinit generator
This script and templates can be used to simplify deployment of a LOCAL Container Linux Kubernetes cluster. It contains 3 steps.

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
curl http://dockerwebserver/master.yaml > master.yaml && sudo coreos-install -d /dev/sda -c master.yaml
```
#### workers
```
curl http://dockerwebserver/worker_IPADRESWORKER.yaml > node.yaml && sudo coreos-install -d /dev/sda -c node.yaml
```
After loading the yamls to the controller and the worker nodes umount the ISO and reboot the servers. You should now have a fully working Kubernetes cluster. Before continuing to the other good stuff test some commands on the cluster with the [testing section](#Testing)


## Addons
1. DNS
```
kubectl create -f addons/dns-addon.yaml
```
2. Dashboard
```
kubectl create -f addons/kubernetes-dashboard.yaml
kubectl proxy
http://localhost:8001/ui
```
3. Heapster && Influx && Grafana
  ```
  kubectl create -f addons/grafana-deployment.yaml
  kubectl create -f addons/grafana-service.yaml
  kubectl create -f addons/heapster-deployment.yaml
  kubectl create -f addons/heapster-service.yam
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
