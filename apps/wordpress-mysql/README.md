# Steps to setup a wordpress cluster

# create a kubernetes secret with the mysql password
kubectl create secret generic mysql-pass --from-file=password.tx

#modify the mysql deployment file to adjust the proper persitant volume claim (size and name)
kubectl create -f mysql.deployment.yaml

#modify the wordpress deployment file to adjust the proper persistant volume claim (size and name)
kubectl create -f wordpress.deployment.yaml

#modify the ingress wordpress object so it can be picked up by the traefik loadbalancer.
#note, it seems wordpress initial setup can not be performed though https.
kubectl create -f wordpress.ing.yaml
