kubectl cp mgmt_config.txt srl01:/mgmt_config.txt
kubectl exec -ti srl01 -- sr_cli source /mgmt_config.txt
