## Cloudinit generator

This script and templates can be used to simplify deployment of a LOCAL Container Linux Kubernetes cluster. It contains 3 steps.

### Modify

Change the config.env with the required settings.

### Generate

Run the create_cloudinit.sh to generate the cloud init yaml files.

### Deploy

Deploy the cloud init files by serving the init yaml e.g through docker.

<code>docker run -ti --rm -p 80:80 -v $PWD/set:/usr/share/nginx/html pblaas/nginx-alpine</code>

After serving the files yaml files boot into CoreOS PXE or ISO and get the yaml and use it to install the system.

#### controller
<code>
curl http://dockerwebserver/master.yaml > master.yaml && sudo coreos-install -d /dev/sda -c master.yaml
</code>

#### workers
<code>
curl http://dockerwebserver/worker_IPADRESWORKER.yaml > node.yaml && sudo coreos-install -d /dev/sda -c node.yaml
</code>


###### Todo
I would like to extend the this project with:
<ul>
<li>DNS</li>
<code>kubectl create -f addons/dns-addon.yaml </code>
<li>Dashboard</li>
<code>kubectl create -f addons/kubernetes-dashboard.yaml </code><br>
<code>kubectl proxy</code><br>
<code>http://localhost:8001/ui</code>
<li>Heapster && Influx</li>
<code>kubectl create -f addons/grafana-deployment.yaml</code><br>
<code>kubectl create -f addons/grafana-service.yaml</code><br>
<code>kubectl create -f addons/heapster-deployment.yaml</code><br>
<code>kubectl create -f addons/heapster-service.yaml</code><br>
<code>kubectl create -f addons/influxdb-deployment.yaml</code><br>
<code>kubectl create -f addons/influxdb-service.yaml</code><br>
<li>Loadbalancing</li>
</ul>

To save yourself some time you could also install all the addons at once.
<code>kubectl create -f addons/</code>

###### Troubleshooting
Interesting reads:
https://github.com/kubernetes/dashboard/blob/master/docs/user-guide/troubleshooting.md

###### Testing

<code>kubectl run nginx --image=nginx --replicas=1 --port=80</code><br>
<code>kubectl expose deployment nginx --port=80 --type=NodePort</code></br>
Grab the port from the nginx process<br>
<code>kubectl get services|grep nginx|awk '{print $4}'|cut -c4-8</code><br>
Browse to your <code>http://master_host:port</code>
