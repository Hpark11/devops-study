#!/usr/bin/env bash
# podnet.sh: my mini "CNI" for the Day 1 assignment (Part A)
#   sudo ./podnet.sh up     # build lab0 + ns1..ns3 (safe to run twice)
#   sudo ./podnet.sh down   # remove everything (safe to run twice)
set -u
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }

add_pod() {
  local ns=$1 ip=$2

  # step 4: create the netns (guarded)
  ip netns list | grep -qw "$ns" || ip netns add "$ns"

  # step 5: lo up
  ip netns exec "$ns" ip link set lo up

  # steps 6–10: only if eth0 does not exist yet in $ns
  #   6  v=... / peer=... / create the veth pair
  #   7  move the pod end into $ns
  #   8  rename it to eth0
  #   9  attach the host end to lab0
  #   10 host end up
  if ! ip netns exec "$ns" ip link show eth0 >/dev/null 2>&1; then
    v=veth$(openssl rand -hex 4)
    peer="eth-$ns"

    ip link add "$v" type veth peer name "$peer"
    ip link set "$peer" netns "$ns"
    ip netns exec "$ns" ip link set "$peer" name "eth0"
    ip link set "$v" master lab0
    ip link set "$v" up
  fi

  # step 11: IP on eth0 (idempotent)
  ip netns exec "$ns" ip addr replace "$ip/24" dev eth0

  # step 12: eth0 up
  ip netns exec "$ns" ip link set eth0 up

  # step 13: default route (idempotent)
  ip netns exec "$ns" ip route replace default via 10.88.0.1
}

up() {
  # steps 1–3: bridge lab0 + 10.88.0.1/24 + up (idempotent)
  ip link show lab0 >/dev/null 2>&1 || ip link add lab0 type bridge
  ip addr replace 10.88.0.1/24 dev lab0
  ip link set lab0 up

  add_pod ns1 10.88.0.11
  add_pod ns2 10.88.0.12
  add_pod ns3 10.88.0.13

  # next stage: ip_forward + 3 iptables rules (each exactly once)
  sysctl -qw net.ipv4.ip_forward=1
  masq=(-s 10.88.0.0/24 ! -o lab0 -j MASQUERADE)
  iptables -t nat -C POSTROUTING "${masq[@]}" 2>/dev/null || iptables -t nat -A POSTROUTING "${masq[@]}"
  iptables -C FORWARD -i lab0 -j ACCEPT 2>/dev/null || iptables -I FORWARD 1 -i lab0 -j ACCEPT
  iptables -C FORWARD -o lab0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || iptables -I FORWARD 1 -o lab0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
}

down() {
  # next stage: remove netns, bridge, iptables rules (no errors when run twice)
  for ns in ns1 ns2 ns3; do
    ip netns list | grep -qw "$ns" && ip netns del "$ns"
  done
  ip link show lab0 >/dev/null 2>&1 && ip link del lab0
  masq=(-s 10.88.0.0/24 ! -o lab0 -j MASQUERADE)
  iptables -t nat -C POSTROUTING "${masq[@]}" >/dev/null 2>&1 && iptables -t nat -D POSTROUTING "${masq[@]}"
  iptables -C FORWARD -i lab0 -j ACCEPT >/dev/null 2>&1 && iptables -D FORWARD -i lab0 -j ACCEPT
  iptables -C FORWARD -o lab0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT >/dev/null 2>&1 && iptables -D FORWARD -o lab0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  # ip_forward: intentionally left at 1 (shared with Docker)
  return 0
}

case "${1:-}" in
  up)   up ;;
  down) down ;;
  *)    echo "usage: $0 up|down"; exit 1 ;;
esac