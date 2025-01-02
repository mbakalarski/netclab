#!/bin/bash


set -e


DIR=$(dirname "$(realpath $0)")


declare withkubevirt=false
if [[ "$#" -eq 1 ]] && [[ ${1} = "nokubevirt" ]]; then withkubevirt=false; fi
if [[ "$#" -eq 1 ]] && [[ ${1} = "kubevirt" ]]; then withkubevirt=true; fi

declare cluster_name="vlab"
declare cluster_node="${cluster_name}-control-plane"


log(){
    local d="$(date -Is -u)"
    local m="$*"
    local me=$(basename "$0")
    echo
    echo "${d} ${HOSTNAME} ${me}: ${m}"
}


wait_dir_has_file(){
    local dirpath="$1"
    local filename="$2"
    local -i timeout=30
    if [[ -n ${3} ]]; then timeout=${3}; fi
    local -i c=0

    log "Test ${filename} in ${dirpath}"

    while [[ ${timeout} -ge 0 ]]
    do
        echo -n "${timeout} "
        c=$(docker exec $cluster_node bash -c "ls -lt ${dirpath}" | grep ${filename} | wc -l)
        if [[ $c -eq 1 ]]; then break ;fi
        sleep 1
        timeout=$(($timeout-1))
    done
    log $(docker exec $cluster_node bash -c "ls -lt ${dirpath}" | grep ${filename})
}


log "Kind cluster ${cluster_name}"
kind delete cluster -n ${cluster_name}
kind create cluster -n ${cluster_name}


wait_dir_has_file "/etc/cni/net.d/" "10-kindnet.conflist"


log "LoadBalancer"
cd "${DIR}/loadbalancer/"
source ./metallb.sh
cd ${DIR}


log "CNI plugins"
unset version
version=$(basename $(curl -s -w %{redirect_url} https://github.com/containernetworking/plugins/releases/latest))
docker exec $cluster_node bash -c "curl -LOs https://github.com/containernetworking/plugins/releases/download/${version}/cni-plugins-linux-amd64-${version}.tgz.sha256"
docker exec $cluster_node bash -c "curl -LOs https://github.com/containernetworking/plugins/releases/download/${version}/cni-plugins-linux-amd64-${version}.tgz"
docker exec $cluster_node bash -c "sha256sum --check cni-plugins-linux-amd64-${version}.tgz.sha256"
docker exec $cluster_node bash -c "cd /opt/cni/bin && tar xvzf /cni-plugins-linux-amd64-${version}.tgz ./bridge"
docker exec $cluster_node bash -c "rm /cni-plugins-linux-amd64-${version}.tgz"

log "custom CNI plugin"
if [[ -f "cni/accept-bridge" ]]; then
    cniplugin="cni/accept-bridge"
else
    curl -LOs "https://raw.githubusercontent.com/mbakalarski/vLab/main/cni/accept-bridge"
    cniplugin="accept-bridge"
fi
docker cp $cniplugin ${cluster_node}:/opt/cni/bin/accept-bridge
docker exec $cluster_node bash -c "chown root:root /opt/cni/bin/accept-bridge"
docker exec $cluster_node bash -c "chmod +x /opt/cni/bin/accept-bridge"

if ${withkubevirt}; then
    log "Test nested virtualization on k8s node"
    nested=$(docker exec $cluster_node bash -c 'cat /sys/module/kvm_intel/parameters/nested | tr -d "\n"')
    echo "nested: ${nested}"
fi

if ${withkubevirt} && [[ ${nested} = "Y" ]]; then
    log "KubeVirt with nested virtualization"
    unset version
    version=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
    kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${version}/kubevirt-operator.yaml"
    kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${version}/kubevirt-cr.yaml"

    unset timeout
    timeout=5m
    log "Deploying, give me ${timeout}"
    kubectl -n kubevirt wait --for=jsonpath='{.status.phase}'=Deployed --timeout=${timeout} kubevirts.kubevirt.io/kubevirt
    kubectl -n kubevirt get kubevirts.kubevirt.io/kubevirt

    log "KubeVirt CDI"
    unset version
    version=$(basename $(curl -s -w %{redirect_url} https://github.com/kubevirt/containerized-data-importer/releases/latest))
    kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$version/cdi-operator.yaml
    kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$version/cdi-cr.yaml

    unset timeout
    timeout=3m
    log "Deploying, give me ${timeout}"
    kubectl -n cdi wait --for=jsonpath='{.status.phase}'=Deployed --timeout=${timeout} cdi/cdi
    kubectl -n cdi get cdi/cdi
fi


log "Cluster bridge and /32 route in place of ptp and 0.0.0.0/0"
docker exec $cluster_node bash -c "sed -i 's#ptp#bridge#' /etc/cni/net.d/10-kindnet.conflist"
docker exec $cluster_node bash -c "sed -i 's#0.0.0.0/0#172.18.0.1/32#' /etc/cni/net.d/10-kindnet.conflist"
docker exec $cluster_node bash -c "sed -i 's#bridge\"#bridge\", \"isGateway\": true, \"isDefaultGateway\": false#' /etc/cni/net.d/10-kindnet.conflist"


log "Multus CNI"
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml
wait_dir_has_file "/etc/cni/net.d/" "00-multus.conf"


log "Done"
