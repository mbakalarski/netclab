kubectl cp mgmt_config.txt srl01:/mgmt_config.txt
kubectl exec -ti srl01 -- sr_cli source /mgmt_config.txt
kubectl exec -ti srl01 -- bash -c 'rm -f /mgmt_config.txt'

sudo ip route add 10.244.0.0/24 via 172.18.0.2

ip=$(kubectl exec -ti srl01 -- bash -c 'ip netns exec srbase-mgmt ip -br addr show dev mgmt0.0' | awk '{printf $3}' | awk -F'/' '{printf $1}')
ping -c3 ${ip}
