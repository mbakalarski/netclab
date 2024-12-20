router="${1}"

kubectl cp mgmt_config.cli ${router}:/mgmt_config.cli
kubectl exec -ti ${router} -- sr_cli source /mgmt_config.cli
kubectl exec -ti ${router} -- bash -c 'rm -f /mgmt_config.cli'

sudo ip route add 10.244.0.0/24 via 172.18.0.2

ip=$(kubectl exec -ti ${router} -- bash -c 'ip netns exec srbase-mgmt ip -br addr show dev mgmt0.0' | awk '{printf $3}' | awk -F'/' '{printf $1}')
ping -c3 ${ip}
