#!/usr/bin/env bash
# Shared helpers for check.sh / probe.sh / fault.sh. Not meant to be run directly.

BR=lab0
GW=10.88.0.1
NS_LIST=(ns1 ns2 ns3)
declare -A NS_IP=([ns1]=10.88.0.11 [ns2]=10.88.0.12 [ns3]=10.88.0.13)

need_root() {
  if [[ $EUID -ne 0 ]]; then echo "run with sudo" >&2; exit 1; fi
}

# Print the host-side veth name paired with <ns>'s eth0 (empty if none).
host_peer() {
  local ns=$1 idx
  idx=$(ip netns exec "$ns" cat /sys/class/net/eth0/iflink 2>/dev/null) || return 0
  ip -o link show | awk -F': ' -v i="$idx" '$1==i {print $2}' | cut -d@ -f1
}

# Classify one ping: OK | NET-UNREACH | HOST-UNREACH | TIMEOUT
# usage: classify_ping <ns> <dst>
classify_ping() {
  local out
  out=$(ip netns exec "$1" ping -n -c 3 -i 0.5 -W 1 -w 5 "$2" 2>&1)
  if [[ $? -eq 0 ]]; then echo OK
  elif grep -q "Network is unreachable" <<<"$out"; then echo NET-UNREACH
  elif grep -q "Destination Host Unreachable" <<<"$out"; then echo HOST-UNREACH
  else echo TIMEOUT
  fi
}
