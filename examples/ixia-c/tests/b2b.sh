alias otgen="${HOME}/ixia-c/otgen/otgen"
export OTG_API="https://$(kubectl get svc otg-controller -o jsonpath='{.status.loadBalancer.ingress[].ip}'):8443"

# curl -sk "${OTG_API}/config"

export OTG_LOCATION_P1="p1"
export OTG_LOCATION_P2="p2"

otgen create flow -s 1.1.1.1 -d 2.2.2.2 -p 80 --rate 1000 | otgen run -k --metrics flow | otgen transform --metrics flow --counters frames | otgen display --mode table
