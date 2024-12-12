### vLab
The idea is to set up virtual testbed with mix of VM and container images,<br>
e.g. Cisco csr1000v and Juniper cRPD or Nokia SR Linux.<br>
I've used KubeVirt for unified control plane and Multus to have more interfaces in virtual routers.<br>
These are really great tools.<br>

To run install script a kubectl and kind tool is needed<br>
and VM images with http access, e.g.:
```
docker run --name www -dt --mount type=bind,source=$HOME/images,target=/usr/share/nginx/html -p 8080:80 nginx:latest
```


To create topology:
```
cd <Lab folder>
kubectl apply -f .
```

and modify a rule for each secondary network, e.g. cni1:
```
docker exec -ti kind-control-plane bash -c "iptables -t nat -I POSTROUTING 1 -o cni1 -j ACCEPT"
```

Then connect to console:
```
virtctl console <router name>
```
*) virtctl - in KubeVirt project; easy installation
