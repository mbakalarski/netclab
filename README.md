### netclab
NETwork Containerized LAB is a tool for running testbeds with mix of VM and container images, e.g. Cisco csr1000v and Juniper cRPD or Nokia SR Linux.<br>
It is based on kind Kubernetes cluster.
Network topologies are defined via k8s manifest files.<br>
KubeVirt is used for VM support and Multus to have more network interfaces.<br>

Install docker at first.<br>
Then install kubectl and kind tool, e.g.
```
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```
```
unset version
version=$(basename $(curl -s -w %{redirect_url} https://github.com/kubernetes-sigs/kind/releases/latest))
curl -Lo ./kind https://kind.sigs.k8s.io/dl/${version}/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```
<br><br>
Run netclab installation script:
```
bash <(curl -Ls "https://raw.githubusercontent.com/mbakalarski/netclab/main/netclab_install.sh") kubevirt
```
or
```
bash <(curl -Ls "https://raw.githubusercontent.com/mbakalarski/netclab/main/netclab_install.sh") nokubevirt
```
Expose VM images via http access, e.g.:
```
docker run --name www -dt --mount type=bind,source=$HOME/images,target=/usr/share/nginx/html -p 8080:80 nginx:latest
```


To create topology:
```
cd <Lab folder>
kubectl apply -f ./manifests/
```


Then connect to console:
```
unset version
version=$(kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.observedKubeVirtVersion}")
curl -L -o virtctl https://github.com/kubevirt/kubevirt/releases/download/${version}/virtctl-${version}-linux-amd64
chmod +x virtctl
sudo mv ./virtctl /usr/local/bin/virtctl
```
```
virtctl console <router name>
```
and/or for containerized router:
```
kubectl exec -ti <router name> -- bash
```
