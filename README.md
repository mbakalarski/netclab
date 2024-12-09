The idea is to set up a virtual testbed with mix of VM and container images, e.g. Cisco csr1000v and the Juniper cSRX.

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
