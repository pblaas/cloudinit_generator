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

###### Addons
1. DNS
```
kubectl create -f addons/dns-addon.yaml
```
1. Dashboard
```
kubectl create -f addons/kubernetes-dashboard.yaml
kubectl proxy</code>
http://localhost:8001/ui
```
1. Heapster && Influx
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

###### Todo
<ul>
<li>Loadbalancing</li>
</ul>


###### Troubleshooting
Interesting reads:
https://github.com/kubernetes/dashboard/blob/master/docs/user-guide/troubleshooting.md

###### Testing

```
kubectl run nginx --image=nginx --replicas=1 --port=80
kubectl expose deployment nginx --port=80 --type=NodePort
```

Grab the port from the nginx process<br>
```
kubectl get services|grep nginx|awk '{print $4}'|cut -c4-8
```
Browse to your <code>http://master_host:port</code>
