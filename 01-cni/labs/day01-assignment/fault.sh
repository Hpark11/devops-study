#!/usr/bin/env bash
# Fault injector for Part C.
#   sudo ./fault.sh inject        # random hidden fault (only one at a time)
#   sudo ./fault.sh inject 7      # a specific fault (for re-practice)
#   sudo ./fault.sh reveal        # show the answer (only AFTER you wrote your diagnosis)
#   sudo ./fault.sh clear         # undo the active fault
#   sudo ./fault.sh status        # is a fault active? (doesn't tell which)
#
# ┌──────────────────────────────────────────────────────────────────────┐
# │  🙈  SPOILERS BELOW. Reading this file = reading the answer key.     │
# │      Diagnose with ip / bridge / iptables / tcpdump / conntrack only. │
# └──────────────────────────────────────────────────────────────────────┘
set -u
cd "$(dirname "$0")" && source ./lib.sh
need_root

STATE=/var/tmp/.lab0-fault
NFAULTS=13

save() { printf '%s\n' "$@" > "$STATE"; chmod 600 "$STATE"; }

inject() {
  local n=$1 p
  case $n in
    1) p=$(host_peer ns1); ip link set "$p" down; save 1 "$p" ;;
    2) ip netns exec ns2 ip route del default; save 2 ;;
    3) ip netns exec ns1 ip route replace default via 10.88.0.254; save 3 ;;
    4) ip netns exec ns3 ip addr del 10.88.0.13/24 dev eth0
       ip netns exec ns3 ip addr add 10.88.0.13/32 dev eth0; save 4 ;;
    5) sysctl -qw net.ipv4.ip_forward=0; save 5 ;;
    6) iptables -t nat -D POSTROUTING -s 10.88.0.0/24 ! -o "$BR" -j MASQUERADE; save 6 ;;
    7) iptables -D FORWARD -i "$BR" -j ACCEPT; save 7 ;;
    8) p=$(host_peer ns3); ip link set "$p" nomaster; save 8 "$p" ;;
    9) ip netns exec ns1 ip neigh replace 10.88.0.12 lladdr 02:00:de:ad:be:ef dev eth0 nud permanent; save 9 ;;
    10) iptables -I FORWARD 1 -s 10.88.0.13 -j DROP; save 10 ;;
    11) ip netns exec ns2 ip link set lo down; save 11 ;;
    12) ip link set "$BR" down; save 12 ;;
    13) ip netns exec ns2 ip link set eth0 arp off; save 13 ;;
    *) echo "unknown fault $n (1-$NFAULTS)"; exit 1 ;;
  esac
}

undo() {
  local n p
  { read -r n; read -r p; } < "$STATE"
  case $n in
    1) ip link set "$p" up ;;
    2) ip netns exec ns2 ip route add default via "$GW" ;;
    3) ip netns exec ns1 ip route replace default via "$GW" ;;
    4) ip netns exec ns3 ip addr del 10.88.0.13/32 dev eth0
       ip netns exec ns3 ip addr add 10.88.0.13/24 dev eth0
       ip netns exec ns3 ip route replace default via "$GW" ;;
    5) sysctl -qw net.ipv4.ip_forward=1 ;;
    6) iptables -t nat -A POSTROUTING -s 10.88.0.0/24 ! -o "$BR" -j MASQUERADE ;;
    7) iptables -I FORWARD 1 -i "$BR" -j ACCEPT ;;
    8) ip link set "$p" master "$BR" ;;
    9) ip netns exec ns1 ip neigh del 10.88.0.12 dev eth0 ;;
    10) iptables -D FORWARD -s 10.88.0.13 -j DROP ;;
    11) ip netns exec ns2 ip link set lo up ;;
    12) ip link set "$BR" up ;;
    13) ip netns exec ns2 ip link set eth0 arp on ;;
  esac
  rm -f "$STATE"
}

reveal() {
  local n; read -r n < "$STATE"
  echo "Fault #$n"
  case $n in
    1) cat <<'E'
Cause:    ns1's host-side veth is admin DOWN ("cable pulled at the switch").
Symptom:  ns1 can reach only itself (lo, own IP). Everything else times out or
          shows HOST-UNREACH. ns2/ns3 can't reach ns1. Others are fine.
Evidence: in ns1: eth0 NO-CARRIER, routes 'linkdown', 'ip neigh' empty.
          host: the veth whose ifindex = ns1's eth0 iflink has no UP flag.
E
;;
    2) cat <<'E'
Cause:    ns2 has no default route.
Symptom:  ns2 -> pods/gateway OK (on-link /24). ns2 -> 8.8.8.8 NET-UNREACH, instant.
Evidence: 'ip route' in ns2 has only the 10.88.0.0/24 line.
E
;;
    3) cat <<'E'
Cause:    ns1's default route points at 10.88.0.254, an on-link IP nobody owns.
Symptom:  ns1 -> pods and 10.88.0.1 OK (on-link). ns1 -> 8.8.8.8 HOST-UNREACH
          (ARP for the *gateway* fails) – not NET-UNREACH, the route exists.
Evidence: 'ip route' default via .254; 'ip neigh' shows 10.88.0.254 INCOMPLETE/FAILED;
          tcpdump -eni lab0 arp: repeated "who-has 10.88.0.254", no reply.
E
;;
    4) cat <<'E'
Cause:    ns3's address is 10.88.0.13/32 instead of /24.
Symptom:  ns3 -> everything except itself NET-UNREACH. Others -> ns3 time out
          (requests arrive; ns3 has no route to send the reply).
Evidence: 'ip addr' shows /32; 'ip route' in ns3 is EMPTY – the connected /24 route
          is gone, and the default route was removed with it (gateway not on-link).
E
;;
    5) cat <<'E'
Cause:    net.ipv4.ip_forward = 0 on the host.
Symptom:  all pod<->pod and pod->10.88.0.1 OK; every pod -> 8.8.8.8 TIMEOUT.
Evidence: sysctl net.ipv4.ip_forward = 0; FORWARD chain counters do NOT move
          while pinging (dropped in routing, before FORWARD).
E
;;
    6) cat <<'E'
Cause:    MASQUERADE rule deleted.
Symptom:  only egress (8.8.8.8) TIMEOUT for all pods.
Evidence: FORWARD -i lab0 counter DOES rise; 'tcpdump -ni eth0 icmp' shows
          src 10.88.0.x leaving the VM; no echo replies.
E
;;
    7) cat <<'E'
Cause:    FORWARD '-i lab0 -j ACCEPT' deleted (Docker's policy DROP takes over).
Symptom:  only egress TIMEOUT for all pods.
Evidence: 'iptables -L FORWARD -v -n': policy DROP counter rises by the number
          of pings; tcpdump on the VM's eth0 shows nothing.
E
;;
    8) cat <<'E'
Cause:    ns3's host veth was detached from the bridge (nomaster). The cable is
          plugged in at both ends, but not into the switch.
Symptom:  ns3 can reach only itself; TIMEOUT to everyone. Others -> ns3 TIMEOUT.
          (Compare fault 1: there, carrier dropped and the ARP cache was FLUSHED.
          Here carrier never changed, so ns3 keeps using its cached MACs
          (STALE -> DELAY -> PROBE) and the frames vanish into the detached veth.
          Once the cache entries go FAILED, new pings turn into HOST-UNREACH.)
Evidence: 'bridge link' lists only 2 ports; ns3's eth0 is still UP/LOWER_UP (!) –
          link state looks perfect, which is what makes this one nasty.
          'ip neigh' in ns3: entries stuck in DELAY/PROBE, then FAILED.
E
;;
    9) cat <<'E'
Cause:    ns1 has a PERMANENT (static) neighbor entry for 10.88.0.12 with a bogus MAC.
Symptom:  only ns1 -> ns2 TIMEOUT. ns2 -> ns1 also TIMEOUT (replies go to the bogus MAC).
          Everything else OK.
Evidence: 'ip neigh' in ns1: 10.88.0.12 lladdr 02:00:de:ad:be:ef PERMANENT;
          tcpdump -eni lab0: ns1's frames go to 02:00:de:ad:be:ef; no ARP is sent.
E
;;
    10) cat <<'E'
Cause:    FORWARD rule '-s 10.88.0.13 -j DROP' inserted at the top.
Symptom:  only ns3 -> 8.8.8.8 TIMEOUT. Pod<->pod is fine (bridged, never FORWARDed).
Evidence: 'iptables -L FORWARD -v -n --line-numbers': rule 1 DROP with a rising counter.
E
;;
    11) cat <<'E'
Cause:    lo is DOWN in ns2.
Symptom:  ns2 -> 127.0.0.1 AND ns2 -> its own IP (10.88.0.12) fail; everything else OK.
          Pinging your own IP uses lo (local table route), so a down lo breaks it.
Evidence: 'ip link show lo' in ns2: no UP flag.
E
;;
    12) cat <<'E'
Cause:    the bridge lab0 itself is admin DOWN.
Symptom:  pods reach only themselves; everything else TIMEOUT (including the gateway).
          The host can still ping 10.88.0.1 (local table!).
Evidence: 'ip link show lab0' no UP flag; 'bridge link': every port is UP/LOWER_UP
          but in state 'disabled'; the pods' own eth0 still show UP/LOWER_UP.
E
;;
    13) cat <<'E'
Cause:    ARP is disabled on ns2's eth0 (NOARP flag).
Symptom:  ns2 can't reach any other host (TIMEOUT) though its link is UP/LOWER_UP and
          routes look fine. Others -> ns2 time out too.
Evidence: 'ip link show eth0' in ns2 shows the NOARP flag. Plain 'ip neigh' shows
          NOTHING – you need 'ip neigh show nud all' to see entries in state NOARP
          whose lladdr is ns2's OWN MAC. tcpdump -eni lab0: frames from ns2 are
          addressed src MAC == dst MAC (its own), so no one accepts them.
E
;;
  esac
}

cmd=${1:-}
case $cmd in
  inject)
    [[ -f $STATE ]] && { echo "a fault is already active – run 'clear' first"; exit 1; }
    ./check.sh >/dev/null || { echo "baseline is not healthy (run sudo ./check.sh) – fix Part A first"; exit 1; }
    inject "${2:-$(( RANDOM % NFAULTS + 1 ))}"
    echo "Fault injected. Something is broken. Start with: sudo ./probe.sh" ;;
  reveal) [[ -f $STATE ]] && reveal || echo "no active fault" ;;
  clear)  [[ -f $STATE ]] && { undo; echo "cleared"; } || echo "no active fault" ;;
  status) [[ -f $STATE ]] && echo "a fault is ACTIVE" || echo "no active fault" ;;
  *) sed -n '2,7p' "$0" ;;
esac
