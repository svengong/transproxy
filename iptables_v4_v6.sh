### ipv6 设置
# TProxy 监听端口，接收使用 TProxy 转发过来的流量
tproxy_port=7893
# 需要被转发的流量打上这个标记

PROXY_FWMARK_IPV6=666
PROXY_ROUTE_TABLE_IPV6=666

# 不转发的 IP，这里只收集了局域网 IP，同理可以过滤掉大陆 IP
ipset create localnetwork6 hash:net family inet6
ipset add localnetwork6 ::/128
ipset add localnetwork6 ::1/128
ipset add localnetwork6 fc00::/7
ipset add localnetwork6 fe80::/10
ipset add localnetwork6 100::/64 # 这个地址是 IPv6 中的私有地址，类似于 IPv4 中的 10.0.0.0/8。它用于内部网络，不会被路由到外部网络
ipset add localnetwork6 ::ffff:0:0/96 # 这些地址用于将 IPv4 地址转换为 IPv6 地址。IPv6 和 IPv4 之间的转换需要一些特殊的地址，这些地址在 IPv4 与 IPv6 的互操作中使用
ipset add localnetwork6 ::ffff:0:0:0/96 # 这些地址用于将 IPv4 地址转换为 IPv6 地址。IPv6 和 IPv4 之间的转换需要一些特殊的地址，这些地址在 IPv4 与 IPv6 的互操作中使用
ipset add localnetwork6 64:ff9b::/96 # 这个地址是 IPv6 中的 IPv4 映射地址，用于 IPv6 主机和 IPv4 主机之间的通信
ipset add localnetwork6 ff00::/8 # 这个地址用于 IPv6 中的多播地址，用于将数据传输到一组设备
ipset add localnetwork6 2002::/16 #  这个地址用于 IPv6 中的 6to4 隧道，用于将 IPv6 流量转换为 IPv4 流量
ipset add localnetwork6 240e:30e::/32 #  电信运营商客户的地址

ip6tables -t mangle -N clash_ipv6
ip6tables -t mangle -F clash_ipv6
ip6tables -t mangle -A clash_ipv6 -m set --match-set localnetwork6 dst -j RETURN
ip6tables -t mangle -A PREROUTING -j clash_ipv6

ip -6 rule add fwmark "$PROXY_FWMARK_IPV6" table "$PROXY_ROUTE_TABLE_IPV6"
ip -6 route add local ::/0 dev lo table "$PROXY_ROUTE_TABLE_IPV6"

ip6tables -t mangle -A clash_ipv6 -p tcp -j TPROXY --on-port "$tproxy_port" --tproxy-mark "$PROXY_FWMARK_IPV6"
ip6tables -t mangle -A clash_ipv6 -p udp -j TPROXY --on-port "$tproxy_port" --tproxy-mark "$PROXY_FWMARK_IPV6"
# 实测没有循环
ip6tables -t mangle -N clash_ipv6_output
ip6tables -t mangle -F clash_ipv6_output
ip6tables -t mangle -A clash_ipv6_output -m set --match-set localnetwork6 dst -j RETURN
ip6tables -t mangle -A OUTPUT -j clash_ipv6_output

ip6tables -t mangle -A clash_ipv6_output -p tcp -j MARK --set-xmark "$PROXY_FWMARK_IPV6"
ip6tables -t mangle -A clash_ipv6_output -p udp -j MARK --set-xmark "$PROXY_FWMARK_IPV6"
##############################################
#ipv4 设置
PROXY_FWMARK_IPV4=444
PROXY_ROUTE_TABLE_IPV4=444
# ROUTE RULES
ip rule add fwmark "$PROXY_FWMARK_IPV4" table "$PROXY_ROUTE_TABLE_IPV4"
ip route add local 0.0.0.0/0 dev lo table "$PROXY_ROUTE_TABLE_IPV4"

ipset create localnetwork hash:net
ipset add localnetwork 0.0.0.0/8
ipset add localnetwork 10.0.0.0/8
ipset add localnetwork 127.0.0.0/8
ipset add localnetwork 169.254.0.0/16
ipset add localnetwork 172.16.0.0/12
ipset add localnetwork 172.17.0.0/16 # docker0
ipset add localnetwork 192.168.0.0/16
ipset add localnetwork 224.0.0.0/4
ipset add localnetwork 240.0.0.0/4

# 透明代理设置
# CREATE TABLE
iptables -t mangle -N clash
iptables -t mangle -F clash
# RETURN LOCAL AND LANS
iptables -t mangle -A clash -m set --match-set localnetwork dst -j RETURN
# REDIRECT
iptables -t mangle -A PREROUTING -j clash
# FORWARD ALL
iptables -t mangle -A clash -p udp -j TPROXY --on-port "$tproxy_port" --tproxy-mark "$PROXY_FWMARK_IPV4"
iptables -t mangle -A clash -p tcp -j TPROXY --on-port "$tproxy_port" --tproxy-mark "$PROXY_FWMARK_IPV4"

# CREATE TABLE
iptables -t mangle -N clash_output
iptables -t mangle -F clash_output
# RETURN LOCAL AND LANS
iptables -t mangle -A clash_output -m set --match-set localnetwork dst -j RETURN
iptables -t mangle -A OUTPUT -j clash_output
iptables -t mangle -A clash_output -p tcp -j MARK --set-xmark "$PROXY_FWMARK_IPV4"
iptables -t mangle -A clash_output -p udp -j MARK --set-xmark "$PROXY_FWMARK_IPV4"





