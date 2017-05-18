# Loadbalancing with Nginx

Label one or more nodes nginx-router.
```
kubectl label node NODEIPS  role=nginx-router
```
Launch the default backend for proper 404 handeling.
```
kubectl create -f default-backend.yaml
```
Launch the deployment set.
```
kubectl create -f nginx-ingress-controller.yaml 
```
