#!/usr/bin/env bash

set -ex

PROXY_FWMARK_IPV4=444
PROXY_ROUTE_TABLE_IPV4=444

ip rule del fwmark $PROXY_FWMARK_IPV4 table $PROXY_ROUTE_TABLE_IPV4 || true
ip route del local 0.0.0.0/0 dev lo table $PROXY_ROUTE_TABLE_IPV4 || true

# iptables -t nat -F
# iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X clash || true
iptables -t mangle -X clash_output || true


PROXY_FWMARK_IPV6=666
PROXY_ROUTE_TABLE_IPV6=666

ip -6 rule del fwmark $PROXY_FWMARK_IPV6 table $PROXY_ROUTE_TABLE_IPV6 || true
ip -6 route del local ::/0 dev lo table $PROXY_ROUTE_TABLE_IPV6 || true

# ip6tables -t nat -F
# ip6tables -t nat -X
ip6tables -t mangle -F
ip6tables -t mangle -X clash_ipv6 || true
ip6tables -t mangle -X clash_ipv6_output || true

ipset destroy localnetwork6
ipset destroy localnetwork

# iptables-save | awk '/^[*]/ { print $1 } 
#                      /^:[A-Z]+ [^-]/ { print $1 " ACCEPT" ; }
#                      /COMMIT/ { print $0; }' | iptables-restore