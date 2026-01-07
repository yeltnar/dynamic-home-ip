# needed for phone... I assume this is good for others too
export GPG_TTY=$(tty)

public_ip="$(curl https://ip.andbrant.com)"

cleanup(){
  # delete unencrypted files
  rm out.zip 
  rm *conf
}

decrypt(){
  sops -d out.zip.enc > out.zip || exit 1 
}

unzip(){
  unzip out.zip || exit 1 
}

update(){
  public_ip="$(curl https://ip.andbrant.com)"
  sed -i -E "s/Endpoint.* [0-9\.]+:/Endpoint = $public_ip:/" *.conf
}

zip(){
  zip out.zip *conf || exit 1 
}

encrypt(){
  sops -e out.zip > out.zip.enc || exit 1 
}

autofix(){
  trap cleanup EXIT # TODO consider if this is desired

  decrypt
  unzip
  update
  zip
  encrypt
}

update_phone(){
  git pull
  decrypt
}

ALLOWED_FUNCTIONS="autofix update_phone"

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

