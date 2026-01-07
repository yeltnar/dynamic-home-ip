cleanup(){
  # delete unencrypted files
  rm out.zip 
  rm *conf
}

decrypt(){
  sops -d out.zip.enc > out.zip || exit 1 
  trap cleanup EXIT # TODO consider if this is desired
}

unzip(){
  unzip out.zip || exit 1 
  trap cleanup EXIT # TODO consider if this is desired
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

  decrypt
  unzip
  update
  zip
  encrypt
}

ALLOWED_FUNCTIONS="autofix"

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

