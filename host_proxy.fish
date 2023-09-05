#!/usr/bin/env fish
# preset chain HOSTPROXY in iptables
# set CUR "$argv[1]"
# set CUR "br-"(docker container inspect nc_caddy  | jq '.[0].NetworkSettings.Networks.nextcloud_default.NetworkID' | cut -c2-13)
set CUR br_nextcloud
set port 8889
echo "nextcloud container network name:" $CUR

sysctl -w net.ipv4.conf."$CUR".route_localnet=1
iptables -t nat -F HOSTPROXY
iptables -t nat -A HOSTPROXY -i "$CUR" -p tcp --dport "$port" -j DNAT --to 127.0.0.1:"$port"
iptables -F HOSTPROXY
iptables -A HOSTPROXY -i "$CUR" -p tcp --dport "$port" -d 127.0.0.1 -j ACCEPT
