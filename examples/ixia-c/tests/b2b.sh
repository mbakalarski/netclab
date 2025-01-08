alias otgen="${HOME}/ixia-c/otgen/otgen"
export OTG_API="https://$(kubectl get svc otg-controller -o jsonpath='{.status.loadBalancer.ingress[].ip}'):8443"

curl -sk "${OTG_API}/config"

export OTG_LOCATION_P1="p1"
export OTG_LOCATION_P2="p2"

otgen create flow --smac 6e:34:fb:b3:9e:2c --dmac 46:0d:10:13:d0:28 -s 192.168.1.2 -d 192.168.1.3 -p 80 --rate 1000 | otgen run -k --metrics flow | otgen transform --metrics flow --counters frames | otgen display --mode table
