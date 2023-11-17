#!/usr/bin/env bash
[ -z "$1" ] && host_ip=xxx || host_ip="$1"
# if inside GFW
[ -z "$2" ] && proxy= || proxy="host.docker.internal:$2"

expired () {
  ssl-cert-check -c "$1" -x 10 | awk '{print $2}' | tail -1 | cut -c-5
}

[ -d ./.private ] || mkdir ./.private/
key_file=./.private/"${host_ip}".crt
[ -f "$key_file" ] && [ "$(expired $key_file)" != "Expir" ] || openssl req -x509 -out ./.private/${host_ip}.crt -keyout ./.private/${host_ip}.key \
  -newkey rsa:4096 -nodes -sha256 -days 90\
  -subj "/CN=${host_ip}" -extensions EXT -config <( \
   printf "[dn]\nCN=${host_ip}\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:${host_ip}\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")

envsub () {
    eval "cat <<EOF
$(<$1)
EOF"
}

envsub ./templates/Caddyfile > Caddyfile
envsub ./templates/docker-compose.yaml > docker-compose.yaml

[ -f ./.private/db.env ] || cat > ./.private/db.env <<EOF
MYSQL_ROOT_PASSWORD=$(pwgen -c -n -y -s -1 -r \$\#\,)
MYSQL_PASSWORD=$(pwgen -c -n -y -s -1 -r \$\#\,)
MYSQL_DATABASE=nextcloud
MYSQL_USER=nextcloud
REDIS_HOST_PASSWORD=$(pwgen -c -n -y -s -1 -r \$\#\,)
EOF
