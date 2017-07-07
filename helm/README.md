## Helm charts

Helm charts are application definitions for Kubernetes.
For more information check the following link: https://github.com/kubernetes/charts

First you need to install and initialize Helm. In short you download a binary and initialize it on your Kubernetes cluster which will run a container 'tiller-deploy' which helps deployment on the k8s cluster.
To install Helm see: https://github.com/kubernetes/helm#docs

These examples assume you have PersistantVolumes available or use a StorageClass.

### Magento Example
```
kubectl create ns magento
helm install --namespace magento --name magento --set magentoUsername=admin,magentoPassword=thisismypw,mariadb.mariadbRootPassword=secretpassword,serviceType=NodePort,magentoHost=magento.k8s.proserve.nl stable/magento
```

#### Magento ingress
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
 name: magento-ingress
 namespace: magento
spec:
 rules:
   - host: magento.k8s.yourdomain.ltd
     http:
       paths:
         - path: /
           backend:
             serviceName: magento-magento
             servicePort: 80
```

### Prestashop Example
```
kubectl create ns prestashop
helm install --namespace prestashop --name prestashop --set prestashopHost=prestashop.k8s.proserve.nl,prestashopUsername=admin,prestashopPassword=thisismypw,mariadb.mariadbRootPassword=secretpassword,serviceType=NodePort stable/prestashop
```

#### Prestashop ingress
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
 name: prestashop-ingress
 namespace: prestashop
spec:
 rules:
   - host: prestashop.k8s.yourdomain.ltd
     http:
       paths:
         - path: /
           backend:
             serviceName: prestashop-prestashop
             servicePort: 80
```

### Joomla Example
```
kubectl create ns joomla
helm install --namespace joomla --name joomla --set joomlaUsername=admin,joomlaPassword=thisismypw,mariadb.mariadbRootPassword=secretpassword,serviceType=NodePort stable/joomla
```

#### Joomla ingress
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
 name: joomla-ingress
 namespace: joomla
spec:
 rules:
   - host: joomla.k8s.yourdomain.ltd
     http:
       paths:
         - path: /
           backend:
             serviceName: joomla-joomla
             servicePort: 80
```

### Wordpress Example
```
kubectl create ns wordpress
helm install --namespace wordpress --name wordpress --set wordpressUsername=admin,wordpressPassword=thisismypw,mariadb.mariadbRootPassword=secretpassword,serviceType=NodePort stable/wordpres
```

#### Wordpress ingress
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
 name: wordpress
 namespace: wordpress
spec:
 rules:
   - host: wordpress.k8s.yourdomain.ltd
     http:
       paths:
         - path: /
           backend:
             serviceName: wordpress-wordpress
             servicePort: 80
```


### Jenkins Example
```
kubectl create jenkins
helm install --namespace jenkins --name jenkins --set Master.ServiceType=NodePort stable/jenkins
printf $(kubectl get secret --namespace jenkins jenkins-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
```

### Kube-Ops-view
```
helm install --name=kube-ops-view stable/kube-ops-view
```

#### Kube-ops Ingress
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
 name: kube-ops-ingress
 namespace: default
spec:
 rules:
   - host: kubeops.k8s.yourdomain.ltd
     http:
       paths:
         - path: /
           backend:
             serviceName: kube-ops-view-kube-ops-view
             servicePort: 80
```
