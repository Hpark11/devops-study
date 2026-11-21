# Day 1 — netns · veth · bridge로 "가짜 Pod 네트워크" 만들기

> ⏱️ 2시간 · 🎯 CNI가 Pod마다 해 주는 일을 손으로 한 번 해 본다

## 💡 개념 요약

| 구성 요소 | 역할 | Kubernetes에서 |
|---|---|---|
| **network namespace** | 독립된 네트워크 스택 (인터페이스, 라우팅, iptables) | Pod 하나 = netns 하나 (pause 컨테이너가 소유) |
| **veth pair** | 양 끝이 연결된 가상 랜선 | 한쪽은 Pod 안 `eth0`, 한쪽은 호스트의 `vethXXXX` |
| **bridge** | 호스트 안의 가상 L2 스위치 | `cni0`, `cbr0` 등 (Cilium은 bridge 없이 eBPF로 연결) |

```
   ┌─────── pod-a (netns) ───────┐      ┌─────── pod-b (netns) ───────┐
   │ eth0 10.244.1.2/24          │      │ eth0 10.244.1.3/24          │
   └──────────┬──────────────────┘      └──────────┬──────────────────┘
              │ veth                               │ veth
   ┌──────────┴────────────── br0 10.244.1.1/24 ───┴──────────────────┐
   │                           host (root netns)                       │
   └────────────────────────────── eth0 ──────────────────────────────┘
```

## 🛠️ 실습

> Linux VM에서 root로 진행. 끝나면 정리 명령으로 원복.

### 1) netns 두 개 만들기
```bash
sudo ip netns add pod-a
sudo ip netns add pod-b
ip netns list
sudo ip netns exec pod-a ip link   # lo만 있고 DOWN 상태
```

### 2) bridge 만들기
```bash
sudo ip link add br0 type bridge
sudo ip addr add 10.244.1.1/24 dev br0
sudo ip link set br0 up
```

### 3) veth pair로 Pod ↔ bridge 연결
```bash
for p in a b; do
  sudo ip link add veth-$p type veth peer name eth0-$p
  sudo ip link set eth0-$p netns pod-$p
  sudo ip netns exec pod-$p ip link set eth0-$p name eth0
  sudo ip link set veth-$p master br0
  sudo ip link set veth-$p up
done
```

### 4) IP 주고 기본 라우트 걸기 (= IPAM + route 설정)
```bash
sudo ip netns exec pod-a ip addr add 10.244.1.2/24 dev eth0
sudo ip netns exec pod-b ip addr add 10.244.1.3/24 dev eth0
for p in a b; do
  sudo ip netns exec pod-$p ip link set eth0 up
  sudo ip netns exec pod-$p ip link set lo up
  sudo ip netns exec pod-$p ip route add default via 10.244.1.1
done
```

### 5) 통신 확인
```bash
sudo ip netns exec pod-a ping -c 2 10.244.1.3   # Pod ↔ Pod (같은 노드)
sudo ip netns exec pod-a ping -c 2 10.244.1.1   # Pod → 게이트웨이(bridge)
```

### 6) 외부로 나가기 (= CNI의 masquerade)
```bash
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -s 10.244.1.0/24 ! -o br0 -j MASQUERADE
sudo ip netns exec pod-a ping -c 2 8.8.8.8
```

### 7) 패킷 관찰
```bash
# 터미널 1
sudo tcpdump -ni br0 icmp
# 터미널 2
sudo ip netns exec pod-a ping -c 3 10.244.1.3
bridge fdb show br br0       # bridge가 학습한 MAC 테이블
ip neigh                      # ARP 테이블
```

### 🧹 정리
```bash
sudo ip netns del pod-a; sudo ip netns del pod-b
sudo ip link del br0
sudo iptables -t nat -D POSTROUTING -s 10.244.1.0/24 ! -o br0 -j MASQUERADE
```

## 💥 Break-it

| 해 볼 것 | 예상 증상 | 왜? |
|---|---|---|
| `ip_forward=0`으로 되돌리기 | 외부 ping 실패, Pod 간은 성공 | 같은 L2는 bridge가 처리, 외부는 L3 포워딩 필요 |
| pod-a의 default route 삭제 | 게이트웨이 너머 전부 실패 | 목적지를 모름 |
| `veth-a`를 down | pod-a만 고립 | 랜선이 뽑힌 것과 같음 |

## ✅ 확인 질문
- [ ] 실제 Kubernetes 노드에서 `ip link`를 쳤을 때 보이는 `vethXXXX`는 어느 Pod와 짝인지 어떻게 찾는가? (힌트: `ip link`의 `@ifN`, Pod 안 `cat /sys/class/net/eth0/iflink`)
- [ ] 이 실습의 각 단계를 CNI 플러그인 종류(main / ipam / meta)에 대응시켜 보라

## 📝 기록
→ `../notes/YYYY-MM-DD-netns-veth.md` 에 [주간 노트 템플릿](../../00-guide/templates/weekly-note.md) 형식으로
