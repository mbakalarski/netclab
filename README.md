### vLab
The idea is to set up virtual testbed with mix of VM and container images,<br>
e.g. Cisco csr1000v and Juniper cRPD or Nokia SR Linux.<br>
I've used KubeVirt for unified control plane and Multus to have more interfaces in virtual routers.<br>

Install docker, kubectl and kind tool at first, e.g.
```
sudo apt -y update && sudo apt -y install podman-docker
```
```
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```
```
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.26.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```
<br><br>
Run vLab installation script:
```
bash <(curl -Ls "https://raw.githubusercontent.com/mbakalarski/vLab/main/vlab_install.sh") kubevirt
```
or
```
bash <(curl -Ls "https://raw.githubusercontent.com/mbakalarski/vLab/main/vlab_install.sh") nokubevirt
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

and use CNI ```accept-bridge``` for each secondary network.


Then connect to console:
```
virtctl console <router name>
```
*) virtctl - in KubeVirt project; easy installation

and/or for containerized router:
```
kubectl exec -ti <router name> -- bash
```
