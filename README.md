# netclab
NETwork Containerized LAB is a tool for running testbeds with mix of VM and container images, e.g. Cisco csr1000v and Juniper cRPD or Nokia SR Linux.<br>
Network topologies are defined via K8s manifest files.<br>
KubeVirt is used for VM support and Multus to have more network interfaces.<br>

## Prerequisites
Linux host or VM with docker installed.<br>

## Tool installation
Install kubectl and kind tool, e.g.
```
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

kind:
```
unset version
version=$(basename $(curl -s -w %{redirect_url} https://github.com/kubernetes-sigs/kind/releases/latest))
curl -Lo ./kind https://kind.sigs.k8s.io/dl/${version}/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

Expose VM images via http access, e.g.:
```
docker run --name www -dt --mount type=bind,source=$HOME/images,target=/usr/share/nginx/html -p 8080:80 nginx:latest
```

<br><br>
Run netclab installation script:
```
bash <(curl -Ls "https://raw.githubusercontent.com/mbakalarski/netclab/main/netclab-kind.sh")
```
or
```
bash <(curl -Ls "https://raw.githubusercontent.com/mbakalarski/netclab/main/netclab-kind.sh") kubevirt
```
with ```kubevirt``` arg for netclab with VM images.<br>

<br><br>
To create topology:
```
cd <Lab folder>
kubectl apply -f ./manifests/
```

<br><br>
Then connect to console.<br>
For VMs install virtctl:
```
unset version
version=$(kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.observedKubeVirtVersion}")
curl -L -o virtctl https://github.com/kubevirt/kubevirt/releases/download/${version}/virtctl-${version}-linux-amd64
chmod +x virtctl
sudo mv ./virtctl /usr/local/bin/virtctl
```
and connect:
```
virtctl console <router name>
```

For containerized router:
```
kubectl exec -ti <router name> -- bash
```
