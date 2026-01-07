public_ip="$(curl https://ip.andbrant.com)"

cleanup(){
  # delete unencrypted files
  rm out.zip 
  rm *conf
}

trap cleanup EXIT

sops -d out.zip.enc > out.zip || exit 1 
unzip out.zip || exit 1 

sed -i -E "s/Endpoint.* [0-9\.]+:/Endpoint = $public_ip:/" *.conf

zip out.zip *conf || exit 1 

sops -e out.zip > out.zip.enc || exit 1 
