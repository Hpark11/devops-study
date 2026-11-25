# Day 1 Assignment: answers

> Name: hspark · Started: YYYY-MM-DD · Finished: YYYY-MM-DD

## Part A: podnet.sh
### Final `check.sh` output
```
hspark@lima-devops:/Users/hspark/Documents/hyunsoo/study/devops-study/01-cni/labs/day01-assignment$ sudo ./check.sh 
== host / bridge
  PASS  bridge lab0 exists
  PASS  lab0 has 10.88.0.1/24
  PASS  lab0 is UP with carrier
  PASS  net.ipv4.ip_forward = 1
== pods
  PASS  ns1 netns exists
  PASS  ns1: lo is UP
  PASS  ns1: eth0 UP with carrier
  PASS  ns1: eth0 has 10.88.0.11/24
  PASS  ns1: default via 10.88.0.1
  PASS  ns1: host veth 'vetha3e75595' uses a random-style name
  PASS  ns1: vetha3e75595 is a port of lab0
  PASS  ns2 netns exists
  PASS  ns2: lo is UP
  PASS  ns2: eth0 UP with carrier
  PASS  ns2: eth0 has 10.88.0.12/24
  PASS  ns2: default via 10.88.0.1
  PASS  ns2: host veth 'veth88e3e417' uses a random-style name
  PASS  ns2: veth88e3e417 is a port of lab0
  PASS  ns3 netns exists
  PASS  ns3: lo is UP
  PASS  ns3: eth0 UP with carrier
  PASS  ns3: eth0 has 10.88.0.13/24
  PASS  ns3: default via 10.88.0.1
  PASS  ns3: host veth 'veth93e5d160' uses a random-style name
  PASS  ns3: veth93e5d160 is a port of lab0
  PASS  pod eth0 MAC addresses are unique
  PASS  lab0 has exactly 3 ports
== iptables (exact rules, exactly once)
  PASS  MASQUERADE rule x1
  PASS  FORWARD -i lab0 ACCEPT x1
  PASS  FORWARD -o lab0 ESTABLISHED x1
== connectivity
  PASS  ns1 -> 10.88.0.1
  PASS  ns1 -> 10.88.0.12
  PASS  ns1 -> 10.88.0.13
  PASS  ns2 -> 10.88.0.1
  PASS  ns2 -> 10.88.0.11
  PASS  ns2 -> 10.88.0.13
  PASS  ns3 -> 10.88.0.1
  PASS  ns3 -> 10.88.0.11
  PASS  ns3 -> 10.88.0.12
  PASS  ns1 -> 8.8.8.8
  PASS  ns2 -> 8.8.8.8
  PASS  ns3 -> 8.8.8.8

RESULT: 42 passed, 0 failed
```
### 3 design decisions
> ✍️ Built from my answers to the guiding questions; 2a, 3b and 3c were completed with Claude's help (marked 🤝).

**1. Temporary Pod-end name: `eth-$ns`**
The Pod end of the veth pair exists in the host namespace for a moment before it's moved into the Pod and renamed to `eth0`, so its name must be unique per Pod. I build it from the netns name (`eth-ns1`, `eth-ns2`, `eth-ns3`). The name also matters for the MAC: on Ubuntu, systemd-udev (`MACAddressPolicy=persistent`) derives an interface's MAC from its name when the interface is created. A fixed name like `tmp` would give every Pod the **same MAC**, so the bridge's fdb would keep moving that MAC between ports and pings would fail intermittently.
Trade-off: a deterministic name collides with a leftover from a crashed run (`File exists`). Real CNIs use a random temporary name to avoid that, and to avoid clashes when many Pods are created in parallel.

**2. Guards vs. `replace`, and one `if` block for steps 6–10**
🤝 Where `ip` has an idempotent command, I use it: `ip addr replace` (bridge IP, Pod IP) and `ip route replace` (default route) succeed whether or not the thing exists. `ip link add` (bridge) and `ip netns add` have no `replace`, so they get a check-then-act guard (`ip link show lab0 … || ip link add …`, `ip netns list | grep -qw … || ip netns add …`).
Steps 6–10 (create the veth pair → move into the Pod → rename to `eth0` → attach to `lab0` → bring up) are one package: if `eth0` already exists in the Pod, the whole package is already installed, so I skip all of it with one `if`. Per-step guards don't work here, because step 6 generates a **new random** host name on every run, so it never "already exists". On a 2nd run it would create a second veth pair, the move would succeed, and only the rename would fail, leaving a stray interface in the Pod and an extra port on `lab0`.

**3. One shared array for the MASQUERADE rule**
My first version checked for one rule but added a different one: `-C` looked for `-s 10.88.0.0/24 ! -o lab0`, while `-A` still had Day 1's `-s 10.244.1.0/24 ! -o br0`. The correct rule was never added, so Pod egress had no NAT and replies never came back.
🤝 Worse, because `-C` never finds the rule that `-A` adds, every run of `up` adds the wrong rule **again**, so after N runs there are N duplicate rules: the script is not idempotent.
🤝 With `masq=(-s 10.88.0.0/24 ! -o lab0 -j MASQUERADE)` the rule is written **once**, and both `-C` and `-A`/`-D` expand the same words via `"${masq[@]}"`. There's only one copy, so the halves can't disagree. (The array keeps each option as a separate argument; a plain string variable would not.)

### MAC trap (didn't hit it)
- **Symptom:** none. `check.sh`: `pod eth0 MAC addresses are unique` → PASS.
- **Evidence:**
  ```
  $ for n in ns1 ns2 ns3; do sudo ip netns exec $n ip -br link show eth0; done
  ns1 eth0@if59  UP  3e:fb:9d:8d:3c:f7
  ns2 eth0@if61  UP  5a:9e:0a:5a:08:50
  ns3 eth0@if63  UP  2e:d5:66:7b:15:f0
  ```
  ns1's MAC `3e:fb:9d:8d:3c:f7` is the same as during my manual test on 11-23, also created as `eth-ns1`. Same name → same MAC, which shows the MAC comes from the name.
- **Cause (why it didn't happen):** each Pod's temporary name is different (decision 1), so each Pod gets a different MAC.
- **Fix:** none needed.

## Part B: second subnet
### B1. Prediction (written before building)

### B2. What actually happened (tcpdump + conntrack)
```
```

### B3. Fix and why

### B4. Rules for lab1 (rule → reason) + the break test

## Part C: fault hunt
<!-- copy this block once per fault -->
### Fault attempt 1
- Symptom matrix:
```
```
- Pattern reading:
- Hypothesis:
- Evidence:
```
```
- Root cause:
- Fix:
- Reveal match?:

### Special challenges
- Identical-matrix faults + decision procedure:
- "Everything looks UP" fault(s):
- HOST-UNREACH ARP proof:

## Part D: investigations
### D1. Pair matching
### D2. fdb aging + flooding
### D3. Neighbor state machine
### D4. Two kinds of dropped
### D5. NAT in one conntrack entry

## Part E: closed-book
1. 
2. 
3. 
4. 
5. 
6. 
