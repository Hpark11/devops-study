# 🧪 Day 1 Assignment: build it, break it, prove it

> ⏱️ 4–6 hours (spread over 2–3 sittings is fine) · 🎯 100 points · 📍 Lima VM `devops` only
> Covers: netns · veth · bridge · IP/routes · ip_forward · FORWARD chain · MASQUERADE · conntrack · ARP/fdb

This isn't a repeat of the lesson. You'll **script** the setup, **extend** it to two subnets, **diagnose hidden faults** with no hints, and **prove** claims with evidence.

## Rules
- Work **inside the VM**: `limactl shell devops`, then `cd ~/Documents/hyunsoo/study/devops-study/01-cni/labs/day01-assignment`. The repo is mounted at the same path. Check that your prompt says `lima-devops`.
- `man ip`, `man iptables`, `ip <cmd> help`, and `--help` are allowed. Copy-pasting from the Day 1 lesson is **not** allowed for Part A. Write it yourself.
- **Don't read `fault.sh`.** It *is* the answer key for Part C.
- Write everything in **`answers.md`** (the template is in this folder). Paste real command output as evidence. A claim without output gets half credit.
- Part E is **closed-book**.

## Files in this folder
| File | Who writes it | What it does |
|---|---|---|
| `README.md` | given | This assignment |
| `answers.md` | **you** | Your report (template provided) |
| `podnet.sh` | **you** | Your setup/teardown script (Part A) |
| `check.sh` | given | Grader: `sudo ./check.sh` (Part A), `sudo ./check.sh --part-b` |
| `probe.sh` | given | Symptom matrix: pings every pod → every target, prints `OK` / `NET-UNREACH` / `HOST-UNREACH` / `TIMEOUT` |
| `fault.sh` | given (🙈 don't read) | Injects hidden faults for Part C |
| `lib.sh` | given | Shared helpers |

---

## Part A: `podnet.sh`, your own mini "CNI" (25 pts)

Write `podnet.sh` so that `sudo ./podnet.sh up` builds this, and `sudo ./podnet.sh down` removes **all** of it:

```
┌─ ns1 ──────────────┐  ┌─ ns2 ──────────────┐  ┌─ ns3 ──────────────┐
│ eth0 10.88.0.11/24 │  │ eth0 10.88.0.12/24 │  │ eth0 10.88.0.13/24 │
└────────╥───────────┘  └────────╥───────────┘  └────────╥───────────┘
     vethXXXXXXXX            vethXXXXXXXX            vethXXXXXXXX
         └──────────────── lab0 10.88.0.1/24 ────────────────┘
                     host: ip_forward=1, NAT to the VM's eth0
```

**Spec (the grader checks every line):**
1. Bridge `lab0` with `10.88.0.1/24`, UP.
2. Netns `ns1`, `ns2`, `ns3`. In each one, `lo` is UP, and an interface named **`eth0`** has the IP above as `/24` and is UP, with `default via 10.88.0.1`.
3. The host-side veth names look like real CNI names: **`veth` + 8 random hex chars** (e.g. `veth3f9a01bc`). Hint: `openssl rand -hex 4`.
4. `net.ipv4.ip_forward = 1`.
5. **Exactly** these iptables rules, **each present exactly once**:
   ```
   -t nat POSTROUTING -s 10.88.0.0/24 ! -o lab0 -j MASQUERADE
   FORWARD -i lab0 -j ACCEPT
   FORWARD -o lab0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
   ```
   (The two FORWARD rules must come **before** Docker's jumps, because of Docker's `policy DROP`.)
6. **Idempotent:** running `up` twice in a row gives no errors and no duplicates. Running `down` twice gives no errors. Look up `iptables -C`.
7. `down` leaves the VM exactly as before. Docker's rules must be untouched.

**Grading:** `sudo ./podnet.sh up && sudo ./podnet.sh up && sudo ./check.sh` must show **0 failed**.

> ⚠️ **Trap you'll probably hit:** the grader also checks that every Pod's MAC address is **unique**. If two Pods end up with the same MAC, some pings will fail *intermittently*, and it will look like a ghost. If that happens, **don't just fix it. Diagnose it** and write in `answers.md` *why* it happened. Hint: what does Ubuntu's udev do when an interface is created, and what name did your Pod-end interface have at that moment?

In `answers.md`: paste your final `check.sh` output and explain **3 design decisions** in your script (e.g. how you made it idempotent, the order of operations, what you name the Pod-end interface before renaming it, and why).

---

## Part B: a second subnet, and the NAT trap (20 pts)

Add a second "node-like" subnet on the same host (you can extend `podnet.sh` or write `podnet-b.sh`):
- Bridge `lab1` with `10.88.1.1/24`, and netns `ns4` with `eth0` = `10.88.1.14/24`, `default via 10.88.1.1`.
- `ns4` must reach `ns1`–`ns3` **through host routing**, and must reach `8.8.8.8`.

**The requirement that makes it interesting:** Pod-to-Pod traffic **must keep the real source IP**. In Kubernetes, Pod-to-Pod NAT is forbidden by the network model, and NetworkPolicy depends on it.

Steps:
1. **B1. Predict** (write it *before* building): with only the Part A rules plus the minimum you need for `ns4`, what source IP will `ns4` see when `ns1` pings it? Why?
2. **B2.** Build it. Prove what really happens: `tcpdump -ni lab1 icmp` while `ns1` pings `ns4`, plus the `conntrack -L` entry. Explain it with the tuple-mirroring rule.
3. **B3.** Fix it so Pod-to-Pod traffic is **not** NATed but egress still is. There's more than one valid fix; explain why yours works and where it sits in POSTROUTING.
4. **B4.** List **every** rule you added for `lab1`, with a one-line reason for each. Remove one FORWARD rule, show what breaks, and put it back.

**Grading:** `sudo ./check.sh --part-b` → 0 failed, plus B1–B4 written up.

---

## Part C: fault hunt 🕵️ (30 pts)

`fault.sh` has 13 hidden faults. Each one is a realistic thing that goes wrong on a node.

**Loop for each fault:**
```
sudo ./fault.sh inject         # random hidden fault
sudo ./probe.sh                # symptom matrix
...investigate with ip / bridge / iptables -v / tcpdump / conntrack / sysctl...
(write your diagnosis in answers.md FIRST)
sudo ./fault.sh reveal         # then compare
sudo ./fault.sh clear          # undo
```

**Do at least 8 faults** (keep re-rolling `inject` until you have 8 different ones; `sudo ./fault.sh inject N` replays a specific one). For each, fill in this block in `answers.md`:

| Field | What to write |
|---|---|
| Symptom matrix | Paste the `probe.sh` output |
| Pattern reading | What the pattern tells you **before** you look at config: one Pod or all? egress only? instant vs. timeout? |
| Hypothesis | Your first guess |
| Evidence | The 1–3 commands + output that **prove** the cause. Not "I looked at it" |
| Root cause | One sentence |
| Fix | The command you would run (then use `fault.sh clear`, or run your fix and `check.sh`) |
| Reveal match? | ✅ / ❌, and if ❌, what misled you |

**Special challenges** (5 of the 30 pts):
- Three different faults produce an **identical** `probe.sh` matrix. Find them, and write a short **decision procedure** (which command to run first, second, third) that tells them apart in under a minute.
- At least one fault leaves every interface `UP,LOWER_UP` and every route looking normal. Which one(s)? What's the only place the evidence shows up?
- Pick one fault where a ping shows `HOST-UNREACH`. Prove it's ARP failing, with a `tcpdump -eni ... arp` capture.

---

## Part D: investigations, proving claims with evidence (15 pts)

Each one needs commands plus output plus a 2–4 line explanation.

1. **D1. Pair-matching blind.** Pretend you don't know which netns is which. Using only `/sys/class/net/eth0/iflink` inside each netns and `ip -o link` on the host, build a table: netns → Pod `eth0` ifindex → host veth name → host veth ifindex. Then do it **from the host side only** (hint: `ip -o link` shows `link-netns`).
2. **D2. Watch the fdb forget.** Set `lab0`'s fdb aging time to **20 seconds** (find how in `man ip-link`; search for `ageing_time`; it's in centiseconds). Ping `ns1 → ns2` once and watch `bridge fdb show br lab0 | grep -v permanent` every 5 s until the entries disappear. Then run `tcpdump -eni lab0` and show that the next unicast frame to a forgotten MAC is **flooded** (it shows up on a third port: capture on ns3's host veth). Set the aging time back to 300 s.
3. **D3. Neighbor state machine.** From `ns1`, ping `ns2` once, then show `ip neigh` in `ns1` at t=0, ~10 s, ~40 s, and right after one more ping. Name every state you saw (`REACHABLE`, `STALE`, `DELAY`, `PROBE`...) and what moved it along.
4. **D4. Two kinds of "dropped."** With a hidden-fault-free baseline, show with **counters** the difference between egress dropped by `ip_forward=0` and egress dropped by a FORWARD `DROP` rule. Use `iptables -L FORWARD -v -n` before and after. You may break things yourself here. Then restore and run `check.sh`.
5. **D5. NAT in one table.** Ping `8.8.8.8` from `ns2`. Show the conntrack entry and annotate which parts were rewritten by MASQUERADE and which by de-NAT.

---

## Part E: closed-book questions (10 pts)

Close everything. Answer each in 2–4 sentences, in English (I'll polish it) or Korean.

1. A Pod gets `ping: connect: Network is unreachable`. List two different misconfigurations that cause it, and explain why no packet ever leaves the Pod.
2. Explain `Destination Host Unreachable` vs. a silent timeout. For each, say what was (or wasn't) on the wire.
3. Why does `ping 10.88.0.1` from the **host** still work when `lab0` is admin-DOWN, but the Pods can't reach it?
4. The host routes `ns1 → 8.8.8.8`. Which fields in the packet change at the routing hop, and which don't? Where does the source-IP change actually happen?
5. Your colleague says: "Pod-to-Pod works on the same node, but every Pod's egress times out." Give your first three checks, in order, and the exact command for each.
6. Why do CNI plugins create the Pod-end veth under a temporary name and rename it to `eth0` only after moving it? Name two problems this avoids.

---

## Rubric
| Part | Points | Full marks when... |
|---|---:|---|
| A | 25 | `check.sh` 0 failed after `up` twice; `down` is clean; 3 design decisions explained; the MAC trap diagnosed (if you hit it) |
| B | 20 | `check.sh --part-b` 0 failed; B1 prediction written *before* building; tuple evidence; fix explained |
| C | 30 | ≥ 8 faults with evidence-based diagnosis (25); special challenges (5) |
| D | 15 | 3 pts each; claims backed by output |
| E | 10 | 6 answers; precise terms (route vs. rule, admin vs. oper, ARP vs. routing) |

When you're done, ask me to **grade it**. I'll read `answers.md`, run `check.sh` myself, and give you a score with feedback. Then clean up with `sudo ./podnet.sh down` and verify that `iptables -S FORWARD` and `iptables -t nat -S POSTROUTING` show only Docker's rules.
