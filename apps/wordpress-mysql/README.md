# Steps to setup a wordpress webserver, database stack.

## Create a kubernetes secret with the mysql password
```
kubectl create secret generic mysql-pass --from-file=password.tx
```

## Modify the mysql deployment file to adjust the proper persitant volume claim (size and name)
```
kubectl create -f mysql.deployment.yaml
```

## Modify the wordpress deployment file to adjust the proper persistant volume claim (size and name)
```
kubectl create -f wordpress.deployment.yaml
```

## Modify the ingress wordpress object so it can be picked up by the traefik loadbalancer.
note, it seems wordpress initial setup can not be performed though https.
```
kubectl create -f wordpress.ing.yaml
```
