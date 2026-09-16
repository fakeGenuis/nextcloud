#!/usr/bin/env fish
# forward traffic from the nextcloud bridge to the host proxy on 127.0.0.1:$port.
# the HOSTPROXY chains and their jumps are created here if missing.
# set CUR "$argv[1]"
# set CUR "br-"(docker container inspect nc_caddy  | jq '.[0].NetworkSettings.Networks.nextcloud_default.NetworkID' | cut -c2-13)
set CUR br_nextcloud
set port 8889
echo "nextcloud container network name:" $CUR

# create the chains and the jumps idempotently (previously preset by iptables.rules)
iptables -t nat -N HOSTPROXY 2>/dev/null
iptables -N HOSTPROXY 2>/dev/null
iptables -t nat -C PREROUTING -j HOSTPROXY 2>/dev/null; or iptables -t nat -I PREROUTING 1 -j HOSTPROXY
iptables -C INPUT -j HOSTPROXY 2>/dev/null; or iptables -I INPUT 1 -j HOSTPROXY

sysctl -w net.ipv4.conf."$CUR".route_localnet=1
iptables -t nat -F HOSTPROXY
iptables -t nat -A HOSTPROXY -i "$CUR" -p tcp --dport "$port" -j DNAT --to 127.0.0.1:"$port"
iptables -F HOSTPROXY
iptables -A HOSTPROXY -i "$CUR" -p tcp --dport "$port" -d 127.0.0.1 -j ACCEPT
