# 📍 Progress Log

> Claude: read this at the start of each session; append at the end.

## Current position
**01-cni → Day 1 assignment (`01-cni/labs/day01-assignment/README.md`) in progress → then Day 2**

Assignment (100 pts): A podnet.sh (check.sh grader) · B second subnet + Pod-to-Pod no-NAT trap · C 13 hidden faults via fault.sh (answer key inside — don't show user) · D investigations · E closed-book. When the user asks to grade: read answers.md, run `sudo ./check.sh [--part-b]` in the VM. All faults and graders were verified in the VM on 2026-11-22. Reference solution isn't in the repo.

VM state: clean (no netns, no br0, FORWARD/POSTROUTING back to Docker defaults, `ip_forward=1`).
Docker sets FORWARD policy DROP and ip_forward=1. Labs that route through the host need FORWARD accept rules (see the Day 1 lesson note).

Carry-over for Day 2 (weak spots from the Day 1 closed-book answer):
- `Destination Host Unreachable` = ARP failed for an on-link dst/gateway. User forgot this, so re-test it.
- User omitted IPAM/default route/ip_forward/MASQUERADE as explicit steps. Revisit the full chain.
- CNI plugin types (main/ipam/meta) mapping is still open (Day 3).

## Log
### 2026-11-20 — Day 0 (environment)
- Checked Mac resources (24 GB / 10 cores); freed disk to 120 GB → VM sized 4 CPU / 8 GB / 60 GB
- Installed Lima VM + tools; hit docker.sock permission denied → fixed via VM restart
- Verified kind cluster creation; learned: fresh node is `NotReady` until CNI is ready; `localhost:8080 refused` = kubectl has no context (cluster was deleted by the smoke test)
- Git: repo initialized (commits `9080da7`, `f101d35`)

### 2026-11-21 → 22 — Day 1 ✅ netns · veth · bridge
- Step 1: new netns has only `lo` (DOWN), empty route table; pause container holds the netns.
- Step 2 (redone step by step): admin vs. oper state; `local` table entry exists even when admin-DOWN (kube-ipvs0 analogy); prefix route only after admin UP, `linkdown` without carrier; `ip rule` local→main; bridge MAC is persistent (udev policy).
- Step 3: veth pair = one command, two ends; moving removes it from the host; `@ifN` cross-reference; `M-DOWN`; LOWERLAYERDOWN chain → br0 NO-CARRIER; after up: LOWER_UP, port `forwarding` (STP off). Bridge carrier = OR of ports.
- Step 4: connected route is the network (`10.244.1.0/24`), not the address; pod↔pod works without a gateway (ttl 64, first ping slower due to ARP); no default → `Network is unreachable`.
- Step 6: Docker's FORWARD policy DROP blocked forwarding (counter +3); added FORWARD accept rules; tcpdump showed src 10.244.1.2 leaves unNATed (user predicted 10.244.1.1, corrected: routing never rewrites IPs); MASQUERADE → src 192.168.5.15; read the conntrack tuples (NAT = non-mirrored reply tuple).
- Step 7: ARP broadcast → unicast reply → ICMP; dst MAC = pod-b (user predicted br0, corrected: longest prefix match picks the on-link route, no `via`); fdb aging (300 s) vs. neigh REACHABLE/STALE.
- Break-it: veth-a down (routes `linkdown`, neigh flushed, timeout); no default route (`Network is unreachable`, pod↔pod OK); ip_forward=0 (timeout, FORWARD counters flat, dropped before FORWARD).
- Mistakes to watch: running lab commands on macOS (check `lima-devops` prompt); typing `link` instead of `ip link` (coreutils `link`); confusing bridge port state vs. neigh state.
- Closed-book note: `01-cni/notes/2026-11-22-netns-veth.md`. Lesson file updated with the Docker FORWARD note.
- User wants a polished-English version of every answer (saved to memory).
