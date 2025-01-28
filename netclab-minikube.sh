#!/bin/bash


set -e


declare withkubevirt=false
if [[ "$#" -eq 1 ]] && [[ ${1} = "nokubevirt" ]]; then withkubevirt=false; fi
if [[ "$#" -eq 1 ]] && [[ ${1} = "kubevirt" ]]; then withkubevirt=true; fi

declare cluster_name="netclab"
declare cluster_node="netclab"


log(){ echo; echo "$(date -Is -u) $*"; }


wait_dir_has_file(){
    local dirpath="$1"
    local filename="$2"
    local -i timeout=30
    if [[ -n ${3} ]]; then timeout=${3}; fi
    local -i c=0

    log "Test ${filename} in ${dirpath}; timeout ${timeout}"

    while [[ ${timeout} -ge 0 ]]
    do
        echo -n "."
        c=$(docker exec $cluster_node bash -c "ls -lt ${dirpath}" | grep ${filename} | wc -l)
        if [[ $c -eq 1 ]]; then break ;fi
        sleep 1
        timeout=$(($timeout-1))
    done
    echo
    docker exec $cluster_node bash -c "ls -lt ${dirpath}*${filename}"
}


custom_cni_plugin(){
  local plugin="$1"
  log "custom CNI plugin ${plugin}"
  docker exec $cluster_node bash -c "curl -Ls -o /opt/cni/bin/${plugin} https://raw.githubusercontent.com/mbakalarski/netclab/main/cni-plugin/${plugin}"
  docker exec $cluster_node bash -c "chown root:root /opt/cni/bin/${plugin}"
  docker exec $cluster_node bash -c "chmod +x /opt/cni/bin/${plugin}"
}


log "k8s cluster ${cluster_name}"
minikube delete -p ${cluster_name}
minikube start -p ${cluster_name} \
  --extra-config=kubelet.cpu-manager-reconcile-period="10s" \
  --extra-config=kubelet.cpu-manager-policy="static" \
  --extra-config=kubelet.kube-reserved="cpu=500m,memory=500Mi" \
  --extra-config=kubelet.feature-gates="CPUManager=true" \
  --extra-config=kubelet.housekeeping-interval="10s"

minikube addons enable metrics-server -p ${cluster_name}


wait_dir_has_file "/etc/cni/net.d/" "conflist"


unset version
version=$(basename $(curl -s -w %{redirect_url} https://github.com/metallb/metallb/releases/latest))
log "MetalLB ${version}"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/${version}/config/manifests/metallb-native.yaml

unset timeout; timeout=3m
log "Deploying, give me ${timeout}"
kubectl -n metallb-system wait --for=jsonpath='{.status.numberReady}'=1 --timeout=${timeout} daemonset.apps/speaker

unset k8s_netname; k8s_netname="${cluster_name}"
k8s_subnet=$(docker network inspect ${k8s_netname} --format json | jq -r .[].IPAM.Config[].Subnet | grep -v \: | awk -F'/' '{printf $1}')
unset prefix; prefix=$(echo "${k8s_subnet}" | awk -F'.' -e '{printf $1"."$2"."$3}')

cat <<EOT | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: lbpool
  namespace: metallb-system
spec:
  addresses:
  - ${prefix}.100 - ${prefix}.250
EOT

cat <<EOT | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2adv
  namespace: metallb-system
spec:
  ipAddressPools:
    - lbpool
EOT


log "Install jq for custom CNI plugins"
docker exec $cluster_node bash -c "apt-get -qy update 2>/dev/null && apt-get -qy install jq 2>/dev/null"
custom_cni_plugin "accept-bridge"
custom_cni_plugin "pod2pod"


if ${withkubevirt}; then
    log "Test nested virtualization on k8s node"
    nested=$(docker exec $cluster_node bash -c 'cat /sys/module/kvm_intel/parameters/nested | tr -d "\n"')
    echo "nested: ${nested}"
fi

running_in_vm=false; if grep -i hypervisor /proc/cpuinfo > /dev/null; then running_in_vm=true; fi

if ${withkubevirt} && ( ! ${running_in_vm} || [[ ${nested} = "Y" ]] ); then
    unset version
    version=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
    log "KubeVirt ${version}"
    kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${version}/kubevirt-operator.yaml"
    kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${version}/kubevirt-cr.yaml"

    unset timeout
    timeout=5m
    log "Deploying, give me ${timeout}"
    kubectl -n kubevirt wait --for=jsonpath='{.status.phase}'=Deployed --timeout=${timeout} kubevirts.kubevirt.io/kubevirt
    kubectl -n kubevirt get kubevirts.kubevirt.io/kubevirt

    unset version
    version=$(basename $(curl -s -w %{redirect_url} https://github.com/kubevirt/containerized-data-importer/releases/latest))
    log "KubeVirt CDI ${version}"
    kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$version/cdi-operator.yaml
    kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$version/cdi-cr.yaml

    unset timeout
    timeout=3m
    log "Deploying, give me ${timeout}"
    kubectl -n cdi wait --for=jsonpath='{.status.phase}'=Deployed --timeout=${timeout} cdi/cdi
    kubectl -n cdi get cdi/cdi
fi


unset version
version=$(basename $(curl -s -w %{redirect_url} "https://github.com/k8snetworkplumbingwg/multus-cni/releases/latest"))
log "Multus ${version}"
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml
wait_dir_has_file "/etc/cni/net.d/" "00-multus.conf" 120


log "Multus default-network"
kubectl apply -f "https://raw.githubusercontent.com/mbakalarski/netclab/main/config/multus-default.yaml"


log "Done"
