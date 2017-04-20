# Loadbalancing with Traefik

Modify some of the Urls in ACME of the configmap.yaml
```
kubectl create -f traefik.configmap.yaml --save-config
```
Label one or more nodes edge-router.
```
kubectl label node NODEIPS  role=edge-router
```
Launch the daemon set.
```
kubectl create -f traefik.ds.yaml
```

UI should be available on edge-route node port :8081
