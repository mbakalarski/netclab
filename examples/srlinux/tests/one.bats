#!/usr/bin/env bats


basedir="examples/srlinux"
manifests=("cni*.yaml" "${ROUTER}_hw.yaml" "${ROUTER}.yaml")


setup_file() {
    for manifest in ${manifests[@]}; do
        kubectl apply -f "${basedir}/manifests/${manifest}"
    done

    kubectl wait --for=jsonpath='{.status.phase}'=Running --timeout=240s pod/${ROUTER}

    timeout=120

    while [[ ${timeout} -ge 0 ]]
    do
        echo "# ${timeout} " >&3
        ip=$(kubectl exec ${ROUTER} -- bash -c 'ip netns exec srbase-mgmt ip -br addr show dev mgmt0.0' | awk '{printf $3}' | awk -F'/' '{printf $1}') || true
        if [[ -n $ip ]]; then break; fi
        sleep 1
        timeout=$(($timeout-1))
    done

    kubectl cp "${basedir}/tests/mgmt_config.cli" "${ROUTER}:/mgmt_config.cli"
    kubectl exec "$ROUTER" -- sr_cli source /mgmt_config.cli
    kubectl exec "$ROUTER" -- bash -c "rm -f /mgmt_config.cli"
    sleep 5
}


teardown_file() {
    for manifest in ${manifests[@]}; do
        kubectl delete -f ${basedir}/manifests/${manifest}
    done
}


@test "ping to mgmt $ROUTER success" {
    ip=$(kubectl exec ${ROUTER} -- bash -c 'ip netns exec srbase-mgmt ip -br addr show dev mgmt0.0' | awk '{printf $3}' | awk -F'/' '{printf $1}')
    run kubectl exec ${ROUTER} -- ip netns exec srbase-mgmt ping -c2 10.10.0.254
    [ "$status" -eq 0 ]
}
