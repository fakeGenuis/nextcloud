#!/usr/bin/env bash
host_ip=xxx

[[ -d ./.private  ]]|| mkdir ./.private/
openssl req -x509 -out ./.private/${host_ip}.crt -keyout ./.private/${host_ip}.key \
  -newkey rsa:4096 -nodes -sha256 -days 90\
  -subj '/CN=${host_ip}' -extensions EXT -config <( \
   printf "[dn]\nCN=${host_ip}\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:${host_ip}\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")

envsub () {
    eval "cat <<EOF
$(<$1)
EOF"
}

envsub ./templates/Caddyfile > Caddyfile
envsub ./templates/docker-compose.yaml > docker-compose.yaml

[[ -f ./.private/db.env ]] || cat > ./.private/db.env <<EOF
MYSQL_ROOT_PASSWORD=$(pwgen -c -n -y -s -1 -r \$\#\,)
MYSQL_PASSWORD=$(pwgen -c -n -y -s -1 -r \$\#\,)
MYSQL_DATABASE=nextcloud
MYSQL_USER=nextcloud
EOF
