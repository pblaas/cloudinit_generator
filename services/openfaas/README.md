# OpenFaas setup

The project which makes this happen can be found at https://github.com/openfaas/faas.

A specific and more rigid explanation on the inner workings of Function as a Service can be found at https://github.com/openfaas/faas/blob/master/guide/deployment_k8s.md.

In short to get this working on your kubernetes cluster follow the following steps.


```
git clone https://github.com/openfaas/faas-netes
kubectl apply -f ./faas.yml,monitoring.yml
```
If your cluster supports RBAC you also need to apply the RBAC yaml.
```
kubectl apply -f ./rbac.yml
```

Next you need to install the faas-cli tool.
https://github.com/openfaas/faas-cli
```
curl -sSL https://cli.openfaas.com | sudo sh
```
