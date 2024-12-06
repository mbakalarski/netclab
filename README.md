The idea is to set up a network test environment and use common tools for VM and container images, such as the Cisco csr1000v VM image and the Juniper cSRX docker image.

Start with:
```
kind create cluster
```

and follow the details from the folders:
- Kubevirt/README.md
- Kind/README.md

then:
```
kubectl apply -f Kubevirt/dv_csr01.yaml
```

```
kubectl apply -f Kubevirt/vm_csr01.yaml
```
<br>
<br>
TODO:<br>
- Multus and more networks/interfaces<br>
- cSRX<br>
