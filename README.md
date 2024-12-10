The idea is to set up virtual testbed with mix of VM and container images, e.g. Cisco csr1000v and Juniper cRPD or Nokia SR Linux.

#### Start with (or a little back):
```
kind create cluster
```

#### CNI plugins:
```
export VERSION=$(basename $(curl -s -w %{redirect_url} https://github.com/containernetworking/plugins/releases/latest))
docker exec -ti kind-control-plane bash -c "curl -LOs https://github.com/containernetworking/plugins/releases/download/${VERSION}/cni-plugins-linux-amd64-${VERSION}.tgz.sha256"
docker exec -ti kind-control-plane bash -c "curl -LOs https://github.com/containernetworking/plugins/releases/download/${VERSION}/cni-plugins-linux-amd64-${VERSION}.tgz"
docker exec -ti kind-control-plane bash -c "sha256sum --check cni-plugins-linux-amd64-${VERSION}.tgz.sha256"
docker exec -ti kind-control-plane bash -c "cd /opt/cni/bin && tar xvzf /cni-plugins-linux-amd64-${VERSION}.tgz"
```

#### KubeVirt with nested virtualization:
```
docker exec -ti kind-control-plane bash -c 'cat /sys/module/kvm_intel/parameters/nested'

export VERSION=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml"
kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml"

kubectl -n kubevirt get kubevirts.kubevirt.io kubevirt -w
```

#### KubeVirt CDI:
```
export VERSION=$(basename $(curl -s -w %{redirect_url} https://github.com/kubevirt/containerized-data-importer/releases/latest))
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-cr.yaml

kubectl -n cdi get cdi cdi -w
```

#### Cluster bridge and /32 route in place of ptp and 0.0.0.0/0:
```
docker exec -ti kind-control-plane bash -c "sed -i 's#ptp#bridge#' /etc/cni/net.d/10-kindnet.conflist"
docker exec -ti kind-control-plane bash -c "sed -i 's#0.0.0.0/0#10.246.17.2/32#' /etc/cni/net.d/10-kindnet.conflist"
docker exec -ti kind-control-plane bash -c "sed -i 's#bridge\"#bridge\", \"isGateway\": true, \"isDefaultGateway\": false#' /etc/cni/net.d/10-kindnet.conflist"
```

#### Multus CNI:
```
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml
```

#### VM images with http access:
```
docker run --name www -dt --mount type=bind,source=$HOME/images,target=/usr/share/nginx/html -p 8080:80 nginx:latest
```

#### When:
```
cd <Lab folder>
kubectl apply -f .
```
```
docker exec -ti kind-control-plane bash -c "iptables -t nat -I POSTROUTING 1 -o cni1 -j ACCEPT"
```

#### Then:
```
virtctl console <router name>
```
