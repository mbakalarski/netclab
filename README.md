The idea is to set up a virtual testbed with mix of VM and container images, e.g. Cisco csr1000v and Juniper cSRX or Nokia SR Linux.

#### Start with:
```
kind create cluster
```

#### follow details in files:
- kubevirt/README.md
- kind/README.md


#### Multus CNI:
```
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml
```

#### VM images with http access:
```
docker run --name www -dt --mount type=bind,source=$HOME/images,target=/usr/share/nginx/html -p 8080:80 nginx:latest
```

#### then:
```
cd <Lab folder>
kubectl apply -f .
```

```
virtctl console <router name>
```
