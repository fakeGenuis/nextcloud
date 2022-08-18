#!/usr/bin/env bash
host_ip=xxx
pass_db=$(pwgen -c -n -y -s -1 -r \$\#\,)

[[ -d ./.private  ]]|| mkdir ./.private/
openssl req -x509 -out ./.private/${host_ip}.crt -keyout ./.private/${host_ip}.key \
  -newkey rsa:4096 -nodes -sha256 -days 90\
  -subj '/CN=${host_ip}' -extensions EXT -config <( \
   printf "[dn]\nCN=${host_ip}\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:${host_ip}\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")

envsub () {
    fi="$1"
    eval "cat <<EOF
    $(<${fi})
EOF"
}

envsub ./templates/Caddyfile > Caddyfile
envsub ./templates/docker-compose.yaml > docker-compose.yaml

cat > ./.private/db.env <<EOF
MYSQL_PASSWORD=$(pwgen -c -n -y -s -1 -r \$\#\,)
MYSQL_DATABASE=nextcloud
MYSQL_USER=nextcloud
EOF

git stash save
