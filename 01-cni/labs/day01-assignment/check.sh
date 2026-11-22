#!/usr/bin/env bash
# Grader for Part A (and Part B with --part-b).
#   sudo ./check.sh            # Part A
#   sudo ./check.sh --part-b   # Part A + Part B
set -u
cd "$(dirname "$0")" && source ./lib.sh
need_root

pass=0; fail=0
ok()  { echo "  PASS  $*"; pass=$((pass+1)); }
bad() { echo "  FAIL  $*"; fail=$((fail+1)); }
chk() { local msg=$1; shift; if "$@" >/dev/null 2>&1; then ok "$msg"; else bad "$msg"; fi; }

echo "== host / bridge"
chk "bridge $BR exists"                 ip link show "$BR" type bridge
chk "$BR has $GW/24"                    sh -c "ip -4 -o addr show dev $BR | grep -qw '$GW/24'"
chk "$BR is UP with carrier"            sh -c "ip link show $BR | grep -q 'LOWER_UP'"
chk "net.ipv4.ip_forward = 1"           sh -c "[ \$(sysctl -n net.ipv4.ip_forward) = 1 ]"

echo "== pods"
for ns in "${NS_LIST[@]}"; do
  ip=${NS_IP[$ns]}
  if ! ip netns list | grep -qw "$ns"; then bad "$ns netns exists"; continue; fi
  ok "$ns netns exists"
  chk "$ns: lo is UP"                   sh -c "ip netns exec $ns ip link show lo | grep -q ',UP'"
  chk "$ns: eth0 UP with carrier"       sh -c "ip netns exec $ns ip link show eth0 | grep -q LOWER_UP"
  chk "$ns: eth0 has $ip/24"            sh -c "ip netns exec $ns ip -4 -o addr show dev eth0 | grep -qw '$ip/24'"
  chk "$ns: default via $GW"            sh -c "ip netns exec $ns ip route show default | grep -q 'via $GW'"
  peer=$(host_peer "$ns")
  if [[ -z $peer ]]; then bad "$ns: host-side veth found"; continue; fi
  if [[ $peer == veth* && $peer != veth-* && ${#peer} -ge 10 ]]; then
    ok "$ns: host veth '$peer' uses a random-style name"
  else
    bad "$ns: host veth '$peer' should look like vethXXXXXXXX (random hex)"
  fi
  chk "$ns: $peer is a port of $BR"     sh -c "ip link show $peer | grep -q 'master $BR'"
done
macs=$(for ns in "${NS_LIST[@]}"; do ip netns exec "$ns" cat /sys/class/net/eth0/address 2>/dev/null; done)
ndup=$(sort <<<"$macs" | uniq -d | wc -l)
[[ $ndup -eq 0 ]] && ok "pod eth0 MAC addresses are unique" || bad "pod eth0 MAC addresses are unique (duplicates: $(sort <<<"$macs" | uniq -d | tr '\n' ' '))"
nports=$(ip -o link show master "$BR" 2>/dev/null | wc -l)
[[ $nports -eq 3 ]] && ok "$BR has exactly 3 ports" || bad "$BR has exactly 3 ports (found $nports)"

echo "== iptables (exact rules, exactly once)"
cnt() { "$@" 2>/dev/null | wc -l; }
n=$(cnt sh -c "iptables -t nat -S POSTROUTING | grep -- '-s 10.88.0.0/24 ! -o $BR -j MASQUERADE'")
[[ $n -eq 1 ]] && ok "MASQUERADE rule x1" || bad "MASQUERADE rule x1 (found $n)"
n=$(cnt sh -c "iptables -S FORWARD | grep -x -- '-A FORWARD -i $BR -j ACCEPT'")
[[ $n -eq 1 ]] && ok "FORWARD -i $BR ACCEPT x1" || bad "FORWARD -i $BR ACCEPT x1 (found $n)"
n=$(cnt sh -c "iptables -S FORWARD | grep -x -- '-A FORWARD -o $BR -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT'")
[[ $n -eq 1 ]] && ok "FORWARD -o $BR ESTABLISHED x1" || bad "FORWARD -o $BR ESTABLISHED x1 (found $n)"

echo "== connectivity"
for src in "${NS_LIST[@]}"; do
  for dst in "$GW" 10.88.0.11 10.88.0.12 10.88.0.13; do
    [[ $dst == "${NS_IP[$src]}" ]] && continue
    chk "$src -> $dst" ip netns exec "$src" ping -c 1 -W 1 "$dst"
  done
done
if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
  for src in "${NS_LIST[@]}"; do chk "$src -> 8.8.8.8" ip netns exec "$src" ping -c 1 -W 2 8.8.8.8; done
else
  echo "  SKIP  egress: the VM itself can't reach 8.8.8.8"
fi

if [[ ${1:-} == --part-b ]]; then
  echo "== Part B"
  chk "bridge lab1 has 10.88.1.1/24"    sh -c "ip -4 -o addr show dev lab1 | grep -qw '10.88.1.1/24'"
  chk "ns4 eth0 has 10.88.1.14/24"      sh -c "ip netns exec ns4 ip -4 -o addr show dev eth0 | grep -qw '10.88.1.14/24'"
  chk "ns1 -> ns4 (10.88.1.14)"         ip netns exec ns1 ping -c 1 -W 1 10.88.1.14
  chk "ns4 -> ns2 (10.88.0.12)"         ip netns exec ns4 ping -c 1 -W 1 10.88.0.12
  chk "ns4 -> 8.8.8.8"                  ip netns exec ns4 ping -c 1 -W 2 8.8.8.8
  # Pod-to-pod must NOT be NATed: the conntrack reply tuple must point back at the real pod IP.
  conntrack -D -p icmp -s 10.88.0.11 -d 10.88.1.14 >/dev/null 2>&1
  ip netns exec ns1 ping -c 1 -W 1 10.88.1.14 >/dev/null 2>&1
  entry=$(conntrack -L -p icmp -s 10.88.0.11 -d 10.88.1.14 2>/dev/null | head -1)
  if grep -q 'src=10.88.1.14 dst=10.88.0.11' <<<"$entry"; then
    ok "ns1 -> ns4 keeps the real source IP (no NAT)"
  else
    bad "ns1 -> ns4 keeps the real source IP (no NAT)   conntrack: ${entry:-<none>}"
  fi
  chk "lab1 has exactly 1 port"         sh -c "[ \$(ip -o link show master lab1 | wc -l) = 1 ]"
fi

echo
echo "RESULT: $pass passed, $fail failed"
[[ $fail -eq 0 ]]
