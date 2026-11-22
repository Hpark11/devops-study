# 📝 Day 1 note: netns · veth · bridge (2026-11-22)

> **One-line summary:** A CNI bridge plugin is "netns + veth pair + bridge port + IP + routes + forwarding/NAT". Each missing piece fails with a different, recognizable symptom.

## 0. Closed-book answer
**Question:** To give a Pod working networking, what must a CNI bridge plugin do, step by step? For each step, what symptom appears if it's skipped?

**My answer (original):**
> make and connect the host's veth - pod's eth0 pair, setup forward rule that allows the request from the eth0 is allowed and the response from outside only started by eth0 is allowed. When there is no route policy in route table, 'Network is unreachable' error occurs and timeout happens when network packet dropped by using stale or broken route. 'Destination Host Unreachable' that I forgot

**Polished:**
> Create a veth pair and connect the host-side veth to the Pod's eth0. Set up FORWARD rules so that requests from the Pod are allowed out, and responses from outside are allowed in only for connections the Pod started. When no route matches the destination, you get `Network is unreachable`. A timeout happens when the packet leaves but is dropped somewhere along the way. (I forgot what causes `Destination Host Unreachable`.)

**Gaps found in review:** I skipped netns/`lo`, the IP address (IPAM), the default route, `ip_forward`, and MASQUERADE as explicit steps. "Route policy" should be "route". A timeout is not caused by a "stale route": the packet *left*, then was dropped or never answered.

## 1. Model answer (step → symptom if missing)
| # | Step | If missing |
|---|---|---|
| 1 | netns (pause container) + `lo` up | Without `lo`, anything talking to 127.0.0.1 inside the Pod fails |
| 2 | veth pair → move one end into netns (rename `eth0`) → host end `master br0` → both ends up | Down end: `NO-CARRIER`/`LOWERLAYERDOWN`, routes `linkdown`, ARP flushed → timeout / `Destination Host Unreachable` |
| 3 | IP on eth0 (IPAM) → kernel adds on-link `/24` route | No address/route → `Network is unreachable` (instant, nothing leaves) |
| 4 | `default via <bridge IP>` (bridge has gateway IP) | Same-subnet works; anything else → `Network is unreachable` |
| 5 | `ip_forward=1` + FORWARD accept (if policy DROP) + MASQUERADE | ip_forward=0 → timeout, FORWARD counters **don't** move. Policy DROP → timeout, policy counter rises. No NAT → request leaves with Pod IP (seen in tcpdump), no reply → timeout |

**Error triage:**
- `Network is unreachable`: no matching route; fails at `connect()`, no packet sent.
- `Destination Host Unreachable`: on-link destination (or gateway) didn't answer **ARP**, an L2 problem.
- Timeout: the packet left and was dropped, or no reply came back. Find *where* with counters or tcpdump.

## 2. Diagram
```
┌─ pod-a ──────────┐                ┌─ pod-b ──────────┐
│ eth0 10.244.1.2  │                │ eth0 10.244.1.3  │
└──────╥───────────┘                └──────╥───────────┘
    veth-a ─────────── br0 ─────────── veth-b      (L2 switch, MAC→port fdb)
                   10.244.1.1                       (host's IP = Pods' gateway)
                       │ ip_forward + FORWARD + MASQUERADE (→ 192.168.5.15)
                     eth0 → internet
```

## 3. Key concepts
1. **Admin vs. oper state:** `UP` flag = you turned it on; `state` / `LOWER_UP` / `NO-CARRIER` = reality. A veth has carrier only if both ends are up; a bridge has carrier if any port does.
2. **`local` table before `main`:** your own IPs are answered even on a DOWN interface (kube-ipvs0 trick). Prefix routes need admin UP (`linkdown` if no carrier).
3. **`@ifN`** pairs veth ends across netns (Pod: `cat /sys/class/net/eth0/iflink` → node: `ip link | grep '^N:'`).
4. **Routing never changes IPs**, only MACs and TTL. `via` only chooses whose MAC to ARP for. Same-subnet traffic never touches the gateway (dst MAC = peer Pod).
5. **NAT is visible in conntrack** when the reply tuple isn't the mirror of the original.
6. **Two learning tables:** bridge fdb (MAC→port, ages out at 300 s, unknown → flood) vs. neighbor (IP→MAC, REACHABLE→STALE).

## 4. Break-it record
| Symptom | Cause | Detection | Fix |
|---|---|---|---|
| Timeout to pod-b, routes `linkdown`, `ip neigh` empty | host veth-a down | `ip link` NO-CARRIER in Pod; veth DOWN on host | `ip link set veth-a up` |
| Pod↔Pod OK, 8.8.8.8 → `Network is unreachable` | default route missing | `ip route` in Pod | add `default via 10.244.1.1` |
| Pod↔Pod & Pod→gateway OK, 8.8.8.8 timeout, FORWARD counters flat | `ip_forward=0` | `sysctl net.ipv4.ip_forward` | set to 1 |
| 8.8.8.8 timeout, FORWARD policy DROP counter rising | Docker set FORWARD policy DROP | `iptables -L FORWARD -v -n` | FORWARD accept rules for br0 |
| 8.8.8.8 timeout, tcpdump shows src 10.244.1.2 on eth0 | no MASQUERADE | `tcpdump -ni eth0` | MASQUERADE in POSTROUTING |

## 5. Senior view
- **Trade-offs:** a bridge is simple but floods ARP/unknown unicast to all Pods; Cilium skips the bridge and answers ARP in eBPF.
- **Operational cautions:** same-node OK but cross-node/egress timeout → check `ip_forward` and the FORWARD chain first. Docker's FORWARD DROP broke k8s in 2017. Duplicate iptables rules from `-I` without `-C`.
- **Decision criteria:** egress SNAT hides Pod IPs (firewalls see node IPs) → consider an egress gateway; conntrack table size is a shared limit.

## ❓ Open questions
- When exactly does the kernel print `LOWERLAYERDOWN` vs `DOWN` for a veth whose peer is in another netns?
- Map each step above to CNI plugin types (main / ipam / meta). This is for Day 3.
