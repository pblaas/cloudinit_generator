# Setup procedure Heketi GluserFS Kubernetes.

Create the heketi service account.
```
kubectl create -f heketi-service-account.yaml
```
Label atleast 3 nodes with proper label tag.
```
kubectl label node NODE storagenode=glusterfs
```
Launch the glusterfs daemonset.
```
kubectl create -f glusterfs-daemonset.yaml
```
Launch the heketi deploy deployment.
```
kubectl create -f deploy-heketi-deployment.yaml
```
Forward the port from the heketi deploy pod to localhost.
```
kubectl port-forward deploy-heketi-XXXXXXXXXX-XXXXX :8080
```
Set the environment variable to communicatie with the heketi-cli tool.
```
export HEKETI_CLI_SERVER=http://localhost:XXXXXX
```

Setup topology.json according to your cluster with proper IP's and devices.

On all k8s nodes run:
`modprobe dm_thin_pool` to be able to communicate to the disks.
Load the topology and format the devices accordingly.
```
heketi-cli topology load --json=topology.json
```
Setup a heketi storage partition.
```
heketi-cli setup-openshift-heketi-storage
```
Copy information to the heketi partition.
```
kubectl create -f heketi-storage.json
```
Delete the heketi deployment components.
```
kubectl delete deploy,services -l name=deploy-heketi
```
Launch the heketi deployement to manage the GlusterFS cluster.
```
kubectl create -f heketi-deployment.yaml
```
Modify storage-class.yaml with service ip heketi received from the cluster.
Then load the storage-class.
```
kubectl create -f storage-class.yaml
```
Run test persistant volume claim to test if auto-volume-claiming works.
```
kubectl create -f test-pvc.yml
kubectl get pvc
```
