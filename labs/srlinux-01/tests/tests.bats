#!/usr/bin/env bats


setup_file() {
    basedir="labs/srlinux-01"
    kubectl apply -f ${basedir}/manifests/
    sleep 30
    sudo ip route del 10.244.0.0/24 || true
    sudo ip route add 10.244.0.0/24 via 172.18.0.2
}


setup() {
    basedir="labs/srlinux-01"
    kubectl cp "${basedir}/tests/mgmt_config.cli" "${router}:/mgmt_config.cli"
    kubectl exec "$router" -- sr_cli source /mgmt_config.cli
    kubectl exec "$router" -- bash -c "rm -f /mgmt_config.cli"
}


@test "ping to mgmt $router success" {
    ip=$(kubectl exec ${router} -- bash -c 'ip netns exec srbase-mgmt ip -br addr show dev mgmt0.0' | awk '{printf $3}' | awk -F'/' '{printf $1}')
    run ping -c3 "$ip"
    [ "$status" -eq 0 ]
}
