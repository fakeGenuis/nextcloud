#!/usr/bin/env bash
[ -z "$1" ] && host_name=xxx || host_name="$1"
# if inside GFW
[ -z "$2" ] && proxy= || proxy="host.docker.internal:$2"
# public hostname with a trusted certificate (gets HSTS); leave xxx to disable
[ -z "$3" ] && public_host=xxx || public_host="$3"
if [ "$public_host" = xxx ]; then
  echo "warning: public_host not set, HSTS will not be sent" >&2
fi

expired () {
  local cert="$1"
  [ -f "$cert" ] || return 0
  if command -v ssl-cert-check >/dev/null 2>&1; then
    ssl-cert-check -c "$cert" -x 10 | awk '{print $2}' | tail -1 | cut -c-5 | grep -q '^Expir'
  else
    openssl x509 -in "$cert" -noout -checkend $((10 * 24 * 3600)) >/dev/null 2>&1 && return 1 || return 0
  fi
}

[ -d ./.private ] || mkdir -p ./.private/
chmod 700 ./.private
crt=./.private/"${host_name}".crt
key=./.private/"${host_name}".key
if [ ! -f "$crt" ] || [ ! -f "$key" ] || expired "$crt"; then
  if printf '%s' "$host_name" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
    san="IP:${host_name}"
  else
    san="DNS:${host_name}"
  fi
  openssl req -x509 -out "$crt" -keyout "$key" \
    -newkey rsa:4096 -nodes -sha256 -days 90 \
    -subj "/CN=${host_name}" -extensions EXT -config <( \
     printf "[dn]\nCN=%s\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=%s\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth" \
       "${host_name}" "${san}")
  chmod 600 "$key"
fi

[ -f ./.private/db.env ] || cat > ./.private/db.env <<EOF
MYSQL_ROOT_PASSWORD=$(pwgen -c -n -y -s -1 -r \$\#\,\&\=)
MYSQL_PASSWORD=$(pwgen -c -n -y -s -1 -r \$\#\,\&\=)
MYSQL_DATABASE=nextcloud
MYSQL_USER=nextcloud
REDIS_HOST_PASSWORD=$(pwgen -c -n -y -s -1 -r \$\#\,\&\=)
EOF
chmod 600 ./.private/db.env
[ -f ./.private/frpc.toml ] && chmod 600 ./.private/frpc.toml

export host_name public_host proxy
for f in Caddyfile docker-compose.yaml; do
  [ -f "$f" ] && cp -a "$f" "$f.bak.$(date +%s)"
done
envsubst '${host_name} ${public_host} ${proxy}' < templates/Caddyfile > Caddyfile
envsubst '${host_name} ${public_host} ${proxy}' < templates/docker-compose.yaml > docker-compose.yaml
