source <(sops -d ./.enc.env)

ip_log_file="/tmp/.ipaddress"

trap 'rm "$ip_log_file"' EXIT

curl -H "Authorization:Bearer $ntfy_token" "$ntfy_endpoint/$ntfy_topic/json?since=5m&poll=1" | 
  jq -r .message |
  jq -r 'select(.device_name | test("vm-nix-vm")) .pub_ip' |
  head -1 > $ip_log_file 

export TF_VAR_home_ip="`cat $ip_log_file`"

echo "TF_VAR_home_ip is $TF_VAR_home_ip"

# tofu init
tofu plan -out ./plan.hcl
# && tofu apply ./plan.hcl
# tofu destroy
