#!/usr/bin/env bats


basedir="examples/srlinux-01"
manifests=("bridge_cni1.yaml" "srl01_hw.yaml" "srl01.yaml")


setup_file() {
    for manifest in ${manifests[@]}; do
        kubectl apply -f "${basedir}/manifests/${manifest}"
    done
    sudo ip route del 10.244.0.0/24 || true
    sudo ip route add 10.244.0.0/24 via 172.18.0.2

    kubectl wait --for=jsonpath='{.status.phase}'=Running --timeout=240s pod/${ROUTER}

    timeout=120

    while [[ ${timeout} -ge 0 ]]
    do
        echo "# ${timeout} " >&3
        ip=$(kubectl exec ${ROUTER} -- bash -c 'ip netns exec srbase-mgmt ip -br addr show dev mgmt0.0' | awk '{printf $3}' | awk -F'/' '{printf $1}') || true
        if [[ $ip =~ "10.244" ]]; then break; fi
        sleep 1
        timeout=$(($timeout-1))
    done

    kubectl cp "${basedir}/tests/mgmt_config.cli" "${ROUTER}:/mgmt_config.cli"
    kubectl exec "$ROUTER" -- sr_cli source /mgmt_config.cli
    kubectl exec "$ROUTER" -- bash -c "rm -f /mgmt_config.cli"
}


function teardown_file() {
    for manifest in ${manifests[@]}; do
        kubectl delete -f ${basedir}/manifests/${manifest}
    done
}


@test "ping to mgmt $ROUTER success" {
    ip=$(kubectl exec ${ROUTER} -- bash -c 'ip netns exec srbase-mgmt ip -br addr show dev mgmt0.0' | awk '{printf $3}' | awk -F'/' '{printf $1}')
    run ping -c3 "$ip"
    [ "$status" -eq 0 ]
}
