# needed for phone... I assume this is good for others too
export GPG_TTY=$(tty)

# this is such an odd way to do this
check_device_set(){
  source local.env
  if [ -z "$device" ]; then
    echo "'device' variable not defined; exting"
    exit 1
  fi
}

check_sed(){
  if sed --version >/dev/null 2>&1; then
    echo "You are using GNU sed (Linux style)"
    # Use: sed -i 's/find/replace/g'
  else
    echo "You are using BSD sed (Mac style); try nix-shell -p gnused; exiting"
    # Use: sed -i "" 's/find/replace/g'
    exit 1
  fi
}

cleanup(){
  check_device_set 
  # delete unencrypted files
  rm "$device.zip" 
  rm *conf
}

decrypt(){
  check_device_set
  sops -d "$device.zip.enc" > "$device.zip" || exit 1 
}

local_unzip(){
  check_device_set
  unzip "$device.zip" || exit 1 
}

get_public_ip(){
  
  source <(sops -d ../.enc.env)

  curl -H "Authorization:Bearer $ntfy_token" "$ntfy_endpoint/$ntfy_topic/json?since=5m&poll=1" | 
    jq -r .message |
    jq -r 'select(.device_name | test("vm-nix-vm")) .pub_ip' |
    head -1
}

update(){
  check_sed
  # public_ip="$(curl https://ip.andbrant.com)"

  public_ip="$(get_public_ip)"

  echo "$public_ip"
  sed -i -E "s/Endpoint.* [0-9\.]+:/Endpoint = $public_ip:/" *.conf
}

local_zip(){
  check_device_set
  zip "$device.zip" *conf || exit 1 
}

encrypt(){
  check_device_set
  sops -e "$device.zip" > "$device.zip.enc" || exit 1 
}

autofix(){
  trap cleanup EXIT # TODO consider if this is desired

  decrypt
  local_unzip
  update
  local_zip
  encrypt
}

update_phone(){
  git pull
  decrypt
}

zip_encrypt(){
  trap 'rm "$device.zip"' EXIT

  local_zip
  encrypt

  echo "zip and encrypt done; consider deleting *conf files"
}

ALLOWED_FUNCTIONS="autofix update_phone decrypt zip_encrypt"

ACTION="$1"

case "$ACTION" in
    "")
        echo "Usage: $0 {function_name}"
        echo "Available functions:"
        echo "$ALLOWED_FUNCTIONS"
        ;;
    *)
        # Check if the user's input is exactly one of the defined functions
        if [[ " $ALLOWED_FUNCTIONS " =~ " $ACTION " ]]; then
            # Execute the function
            "$ACTION"
        else
            echo "Error: '$ACTION' is not a valid internal function."
            exit 1
        fi
        ;;
esac

