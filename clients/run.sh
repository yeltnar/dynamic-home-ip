# needed for phone... I assume this is good for others too
export GPG_TTY=$(tty)

source local.env

if [ -z "$device" ]; then
  echo "'device' variable not defined; exting"
  exit 1
fi

cleanup(){
  # delete unencrypted files
  rm "$device.zip" 
  rm *conf
}

decrypt(){
  sops -d "$device.zip.enc" > "$device.zip" || exit 1 
}

local_unzip(){
  unzip "$device.zip" || exit 1 
}

update(){
  public_ip="$(curl https://ip.andbrant.com)"
  sed -i -E "s/Endpoint.* [0-9\.]+:/Endpoint = $public_ip:/" *.conf
}

local_zip(){
  zip "$device.zip" *conf || exit 1 
}

encrypt(){
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

