#!/bin/bash
################################################################################
# MIT License
#
# Copyright (c) 2024 mbakalarski
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
################################################################################
set -e


declare cluster_name="vlab"
declare cluster_node="${cluster_name}-control-plane"


log(){
    local d=$(date -Is)
    local m="$1"
    local me=$(basename "$0")
    echo
    echo "${d} ${HOSTNAME} ${me}: ${m}"
}


log "Kind cluster ${cluster_name}"
kind delete cluster -n ${cluster_name}
kind create cluster -n ${cluster_name}


log "CNI plugins"
unset version
version=$(basename $(curl -s -w %{redirect_url} https://github.com/containernetworking/plugins/releases/latest))
docker exec -ti $cluster_node bash -c "curl -LOs https://github.com/containernetworking/plugins/releases/download/${version}/cni-plugins-linux-amd64-${version}.tgz.sha256"
docker exec -ti $cluster_node bash -c "curl -LOs https://github.com/containernetworking/plugins/releases/download/${version}/cni-plugins-linux-amd64-${version}.tgz"
docker exec -ti $cluster_node bash -c "sha256sum --check cni-plugins-linux-amd64-${version}.tgz.sha256"
docker exec -ti $cluster_node bash -c "cd /opt/cni/bin && tar xvzf /cni-plugins-linux-amd64-${version}.tgz"
docker exec -ti $cluster_node bash -c "rm /cni-plugins-linux-amd64-${version}.tgz"


log "KubeVirt with nested virtualization"
nested=$(docker exec -ti $cluster_node bash -c 'cat /sys/module/kvm_intel/parameters/nested | tr -d "\n"')
if [[ ${nested} = "Y" ]]; then
    unset version
    version=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
    kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${version}/kubevirt-operator.yaml"
    kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${version}/kubevirt-cr.yaml"

    unset timeout
    timeout=5m
    log "Deploying, give me ${timeout}"
    kubectl -n kubevirt wait --for=jsonpath='{.status.phase}'=Deployed --timeout=${timeout} kubevirts.kubevirt.io/kubevirt
    kubectl -n kubevirt get kubevirts.kubevirt.io/kubevirt
fi


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


log "Cluster bridge and /32 route in place of ptp and 0.0.0.0/0"
docker exec -ti $cluster_node bash -c "sed -i 's#ptp#bridge#' /etc/cni/net.d/10-kindnet.conflist"
docker exec -ti $cluster_node bash -c "sed -i 's#0.0.0.0/0#10.246.17.2/32#' /etc/cni/net.d/10-kindnet.conflist"
docker exec -ti $cluster_node bash -c "sed -i 's#bridge\"#bridge\", \"isGateway\": true, \"isDefaultGateway\": false#' /etc/cni/net.d/10-kindnet.conflist"


log "Multus CNI"
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml

declare -i c=0
unset timeout
timeout=30

log "Deploying, give me ${timeout}s or less"
until [[ $c -eq 1 ]] || [[ ${timeout} -le 0 ]]
do
    c=$(docker exec -ti $cluster_node bash -c "ls -lt /etc/cni/net.d/" | grep 00-multus.conf | wc -l)
    sleep 1
    timeout=$(($timeout-1))
done

log "Done"

