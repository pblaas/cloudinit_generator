kubectl run --namespace=microbot access --rm -ti --image busybox /bin/sh
# while [ "true" ]; do wget -q --timeout=2 microbot -O -|grep hostname|cut -d: -f2|tr -d "\</p\>"; sleep 2; done

