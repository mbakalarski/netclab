# KubeVirt (with nested virtualization)
```
docker exec -ti kind-control-plane bash -c 'cat /sys/module/kvm_intel/parameters/nested'

export VERSION=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml"
kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml"

kubectl -n kubevirt get kubevirts.kubevirt.io kubevirt -w
```

# Containerized Data Importer CDI
```
export VERSION=$(basename $(curl -s -w %{redirect_url} https://github.com/kubevirt/containerized-data-importer/releases/latest))
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-cr.yaml

kubectl -n cdi get cdi cdi -w
```

# VM images with http access
```
docker run --name www -dt --mount type=bind,source=$HOME/images,target=/usr/share/nginx/html -p 8080:80 nginx:latest
```
