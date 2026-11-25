# 📝 Day 2 note: routing · iptables chains · conntrack (2026-11-25)

> **One-line summary:** A ClusterIP is just a DNAT rule in PREROUTING. conntrack makes the NAT decision once per connection and undoes it on the reply, but only for packets that actually pass through the host's netfilter hooks.

## 0. Closed-book answer
**Question:** A Pod curls a ClusterIP Service. Trace the request and the reply through the node's kernel: which hook does what (routing decision, DNAT, filter, conntrack), and why does the reply look like it came from the ClusterIP? What breaks if (a) the backend is on the same bridge without `br_netfilter`, and (b) the conntrack table is full?

**My answer (polished):**
> When a Pod curls a ClusterIP Service, the request passes through the PREROUTING hook (raw:PREROUTING → mangle:PREROUTING → nat:PREROUTING) before the routing decision. Destination NAT happens in nat:PREROUTING: the destination changes from the Service's virtual IP to a real backend IP. Without `br_netfilter`, if the backend shares the same bridge as the client Pod, the backend knows it can reach the Pod directly and replies straight to it. The Pod receives a reply from an IP it never contacted, so it rejects it. With `br_netfilter`, bridged frames also go through iptables and conntrack, so the reply is translated back. When the conntrack table is full, further packets are dropped.

**Gaps found in review:**
- Stopped at the routing decision: the request then goes **filter:FORWARD → nat:POSTROUTING** before leaving.
- The core "why" was missing: **conntrack** records the NAT on the **first packet** (reply tuple already says the backend at `[NEW]`) and **de-NATs** the reply's source back to the ClusterIP. That is why the reply looks like it came from the ClusterIP.
- "Rejects it" → specifically a TCP **RST**, because the SYN-ACK comes from an unknown address.
- "Every request went through the bridge": more precisely, `br_netfilter` makes **bridged (L2) frames pass the iptables hooks**, so conntrack sees the reply.
- Conntrack full: **new** connections are dropped (silent timeout, `table full, dropping packet` in `dmesg`); **existing** ones keep working.

## 1. Model answer
1. Request: `raw/mangle/nat:PREROUTING` → **DNAT** ClusterIP:port → backend:port (only the first packet hits the nat table; conntrack stores the result).
2. **Routing decision** on the *new* destination (that's why DNAT must be in PREROUTING; host-originated traffic uses OUTPUT instead) → `filter:FORWARD` → `nat:POSTROUTING`.
3. Reply: conntrack matches it to the entry and **reverses the DNAT** (src backend → ClusterIP), so the client sees the Service IP.
4. (a) Same-bridge backend without `br_netfilter`: the reply is switched at L2 and skips conntrack → no de-NAT → client gets a SYN-ACK from the backend IP → **RST** → curl `000`. Fix: `br_netfilter` + `net.bridge.bridge-nf-call-iptables=1` (Kubernetes requirement), or hairpin SNAT.
5. (b) Conntrack full: new flows (TCP SYNs, DNS UDP queries, health checks) are dropped silently → timeouts everywhere at once; ASSURED existing flows survive. Detect: `dmesg` `table full`, `conntrack -C` vs `nf_conntrack_max`.

## 2. Diagram
```
 Pod ─▶ PREROUTING (raw → [mangle] → nat: DNAT) ─▶ [routing] ─▶ FORWARD (filter) ─▶ POSTROUTING (nat) ─▶ backend
                       ▲ conntrack: entry created on 1st packet, reply tuple = backend
 backend reply ─▶ (needs to pass netfilter!) ─▶ conntrack de-NAT: src backend → ClusterIP ─▶ Pod
```

## 3. Lab results
| Lab | Result |
|---|---|
| `ip route get … iif lab0` | Each hop uses its own table: ns1 → via 10.88.0.1; host → via 192.168.5.2 dev eth0; hairpin → `<redirect>` |
| TRACE (`xtables-monitor --trace`) | raw → nat(LIMADNS) → [routing: OUT=eth0, TTL 63] → filter:FORWARD `-i lab0` → nat:POSTROUTING MASQUERADE. No mangle: nf_tables only has tables someone created |
| Fake Service DNAT to same bridge | `000`; tcpdump: SYN → DNAT → SYN-ACK straight ns2→ns1 (ns1's MAC) → RST |
| + `br_netfilter` | `200`; bridged frames now match FORWARD (`IN=lab0 OUT=lab0`, so both rules can match and order affects counters) |
| `conntrack -E` | NEW (reply tuple already DNATed, UNREPLIED) → SYN_RECV → ESTABLISHED (432000 s, ASSURED) → FIN_WAIT → LAST_ACK → TIME_WAIT (120 s) → DESTROY |
| iptables-save vs nft | 52 vs 126 lines: same rules, verbose syntax; `counter` on every rule; DNAT counter = SYNs only (60 B each) |

## 4. Break-it record
| Symptom | Cause | Detection | Fix |
|---|---|---|---|
| curl `000` after ~19 loops; `sudo: unable to resolve host` | `nf_conntrack_max=100`; each sudo made several DNS UDP entries (hostname not in /etc/hosts) + TIME_WAIT entries | `dmesg`: `table full, dropping packet`; `conntrack -C` = 100 | restore max; in prod: connection reuse, size the table, alert on entries/limit |

## 5. Senior view
- **Trade-offs:** iptables rules are linear; kube-proxy nftables mode uses maps (one lookup). Cilium avoids bridge + iptables entirely.
- **Operational cautions:** stale UDP conntrack entries after backend changes (CoreDNS) → kube-proxy deletes them; ESTABLISHED timeout is 5 days; mixing iptables-legacy and iptables-nft gives "invisible" rules (`iptables -V`); don't edit iptables-nft tables with `nft`.
- **Decision criteria:** short-lived connections without keep-alive multiply TIME_WAIT entries → conntrack pressure; alert on `node_nf_conntrack_entries / limit`.

## ❓ Open questions
- Hairpin SNAT (kube-proxy masquerades a Pod reaching itself through its own Service): try it instead of `br_netfilter`.
- What exactly does Cilium do instead of conntrack-in-netfilter (its own eBPF CT map)? Week 2.
