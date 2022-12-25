#!/bin/bash

# iptables -A OUTPUT -p tcp -s 0/0 -d 0.0.0.0/8 -j DROP
# iptables -A OUTPUT -p tcp -s 0/0 -d 10.0.0.0/8 -j DROP
iptables -A OUTPUT -p tcp -s 0/0 -d 100.64.0.0/10 -j DROP
iptables -A OUTPUT -p tcp -s 0/0 -d 169.254.0.0/16 -j DROP
# iptables -A OUTPUT -p tcp -s 0/0 -d 172.16.0.0/12 -j DROP
iptables -A OUTPUT -p tcp -s 0/0 -d 192.0.0.0/24 -j DROP
iptables -A OUTPUT -p tcp -s 0/0 -d 192.0.2.0/24 -j DROP
iptables -A OUTPUT -p tcp -s 0/0 -d 192.88.99.0/24 -j DROP
iptables -A OUTPUT -p tcp -s 0/0 -d 192.168.0.0/16 -j DROP
iptables -A OUTPUT -p tcp -s 0/0 -d 198.18.0.0/15 -j DROP
iptables -A OUTPUT -p tcp -s 0/0 -d 198.51.100.0/24 -j DROP
iptables -A OUTPUT -p tcp -s 0/0 -d 203.0.113.0/24 -j DROP
iptables -A OUTPUT -p tcp -s 0/0 -d 224.0.0.0/4 -j DROP
iptables -A OUTPUT -p tcp -s 0/0 -d 240.0.0.0/4 -j DROP

# iptables -A OUTPUT -p udp -s 0/0 -d 0.0.0.0/8 -j DROP
# iptables -A OUTPUT -p udp -s 0/0 -d 10.0.0.0/8 -j DROP
iptables -A OUTPUT -p udp -s 0/0 -d 100.64.0.0/10 -j DROP
iptables -A OUTPUT -p udp -s 0/0 -d 169.254.0.0/16 -j DROP
# iptables -A OUTPUT -p udp -s 0/0 -d 172.16.0.0/12 -j DROP
iptables -A OUTPUT -p udp -s 0/0 -d 192.0.0.0/24 -j DROP
iptables -A OUTPUT -p udp -s 0/0 -d 192.0.2.0/24 -j DROP
iptables -A OUTPUT -p udp -s 0/0 -d 192.88.99.0/24 -j DROP
iptables -A OUTPUT -p udp -s 0/0 -d 192.168.0.0/16 -j DROP
iptables -A OUTPUT -p udp -s 0/0 -d 198.18.0.0/15 -j DROP
iptables -A OUTPUT -p udp -s 0/0 -d 198.51.100.0/24 -j DROP
iptables -A OUTPUT -p udp -s 0/0 -d 203.0.113.0/24 -j DROP
iptables -A OUTPUT -p udp -s 0/0 -d 224.0.0.0/4 -j DROP
iptables -A OUTPUT -p udp -s 0/0 -d 240.0.0.0/4 -j DROP
