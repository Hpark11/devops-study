# 📍 Progress Log

> Claude: read this at the start of each session; append at the end.

## Current position
**01-cni → Day 1 (`01-cni/lessons/day01-netns-veth-bridge.md`) → next: Step 3 (veth pair)**

State in the VM right now (may persist unless the VM was restarted — netns/bridge are lost on reboot):
- netns `pod-a`, `pod-b` created; `lo` set UP in pod-a
- bridge `br0` created, `10.244.1.1/24`, UP but `NO-CARRIER` (no ports yet)
- No veth yet. Check with `ip netns list; ip link show br0` before continuing; if gone, redo steps 1–2 quickly.

Pending predictions for Step 3 (ask user before running):
- (a) After `ip link set eth0-a netns pod-a`, does `eth0-a` still appear in host `ip link`?
- (b) After attaching veth-a to br0 and bringing it up, does br0 still show `NO-CARRIER`?
- Point out the `@ifN` suffix (how to map host veth ↔ Pod).

Remaining Day 1: Step 4 (IP + default route), 5 (ping pod↔pod), 6 (ip_forward + MASQUERADE — key question: without MASQUERADE, packet leaves but why no reply?), 7 (tcpdump on br0: ARP before ICMP; `bridge fdb`, `ip neigh`), Break-it table, cleanup, closed-book note.

## Log
### 2026-11-20 — Day 0 (environment)
- Checked Mac resources (24 GB / 10 cores); freed disk to 120 GB → VM sized 4 CPU / 8 GB / 60 GB
- Installed Lima VM + tools; hit docker.sock permission denied → fixed via VM restart
- Verified kind cluster creation; learned: fresh node is `NotReady` until CNI is ready; `localhost:8080 refused` = kubectl has no context (cluster was deleted by the smoke test)
- Git init (step 6): **not confirmed** — ask user

### 2026-11-21 — Day 1 (in progress)
- Step 1 ✅ Prediction "one interface" correct: new netns has only `lo`, DOWN, empty route table. Learned: `lo` must be brought up (CNI `loopback` plugin), pause container holds the netns.
- Step 2 ✅ Host can ping 10.244.1.1 (own address via local table, works even with NO-CARRIER); pod-a gets `Network is unreachable` (no route). Learned error-type triage: unreachable vs host unreachable vs timeout vs refused.
- Concepts explained so far: what Lima is, limactl flags, `ip link` vs `ip addr` vs `ip route`.
