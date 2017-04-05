## Cloudinit generator

This script and templates can be used to simplify deployment of a Container Linux Kubernetes cluster. It contains of just 3 steps.

### Modify

Change the config.env with the required settings.

### Generate

Run the create_coudinit.sh to generate the cloud init yaml files.

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
<li>Heapster</li>
<li>Influx</li>
</ul>

###### Troubleshooting
Interesting reads:
https://github.com/kubernetes/dashboard/blob/master/docs/user-guide/troubleshooting.md
