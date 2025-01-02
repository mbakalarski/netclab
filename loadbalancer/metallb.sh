#!/bin/bash


version=$(basename $(curl -s -w %{redirect_url} https://github.com/metallb/metallb/releases/latest))
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/${version}/config/manifests/metallb-native.yaml


kind_subnet=$(docker network inspect kind --format json | jq -r .[].IPAM.Config[].Subnet | grep -v \: | awk -F'/' '{printf $1}')
prefix=$(echo "${kind_subnet}" | awk -F'.' -e '{printf $1"."$2"."$3}')


cat <<EOF > patch.yaml
- op: replace
  path: /spec/addresses/0
  value: ${prefix}.100 - ${prefix}.250
EOF


timeout=3m
log "Deploying, give me ${timeout}"
kubectl -n metallb-system wait --for=jsonpath='{.status.numberReady}'=1 --timeout=${timeout} daemonset.apps/speaker


kubectl kustomize .
kubectl apply -k .
rm patch.yaml
