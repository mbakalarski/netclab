### after KubeVirt installation

```
docker exec -ti kind-control-plane bash -c 'curl -LOs https://github.com/containernetworking/plugins/releases/download/v1.6.1/cni-plugins-linux-amd64-v1.6.1.tgz.sha256'
docker exec -ti kind-control-plane bash -c 'curl -LOs https://github.com/containernetworking/plugins/releases/download/v1.6.1/cni-plugins-linux-amd64-v1.6.1.tgz'
docker exec -ti kind-control-plane bash -c 'sha256sum --check cni-plugins-linux-amd64-v1.6.1.tgz.sha256'
docker exec -ti kind-control-plane bash -c 'cd /opt/cni/bin && tar xvzf /cni-plugins-linux-amd64-v1.6.1.tgz ./bridge'

cat <<EOF > kindnet_bridge.conflist
{
  "cniVersion": "0.3.1",
  "name": "kindnet",
  "plugins": [
    {
      "type": "bridge",
      "ipMasq": false,
      "isGateway": true,
      "isDefaultGateway": false,
      "ipam": {
        "type": "host-local",
        "dataDir": "/run/cni-ipam-state",
        "ranges": [
          [
            {
              "subnet": "10.244.0.0/24"
            }
          ]
        ],
		"routes": [
			{ "dst": "10.246.17.2/32", "gw": "10.244.0.1" }
		]
      },
      "mtu": 1500
    },
    {
      "type": "portmap",
      "capabilities": {
        "portMappings": true
      }
    }
  ]
}
EOF

docker cp kindnet_bridge.conflist kind-control-plane:/etc/cni/net.d/10-kindnet.conflist
docker exec -ti kind-control-plane bash -c 'chown root:root /etc/cni/net.d/10-kindnet.conflist'
docker exec -ti kind-control-plane bash -c 'chmod go-w /etc/cni/net.d/10-kindnet.conflist'
```
