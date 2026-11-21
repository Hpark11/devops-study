# Day 2 — 라우팅 · iptables 체인 · conntrack

> ⏱️ 2시간 · 🎯 패킷이 커널 안에서 어떤 순서로 hook을 지나가는지 그림으로 그릴 수 있다

## 💡 개념 요약

```
 들어오는 패킷 ─▶ PREROUTING ─▶ [라우팅 결정] ─┬─▶ INPUT ─▶ 로컬 프로세스
               (raw→mangle→nat)              │
                                             └─▶ FORWARD ─▶ POSTROUTING ─▶ 나가는 패킷
 로컬 프로세스 ─▶ OUTPUT ─▶ [라우팅 결정] ─────────────────▶ POSTROUTING
```

| 개념 | 핵심 |
|---|---|
| 라우팅 테이블 | `ip route` / policy routing `ip rule` |
| iptables 테이블 | raw → mangle → **nat** → filter 순 |
| DNAT | PREROUTING/OUTPUT의 nat 테이블 (Service ClusterIP → Pod IP) |
| SNAT/MASQUERADE | POSTROUTING의 nat 테이블 |
| conntrack | 연결 상태 추적, NAT 결과를 기억 → 응답 패킷 역변환 |
| nftables | iptables의 후속, K8s 1.31+ kube-proxy nftables 모드 |

## 🛠️ 실습
1. Day 1 환경을 다시 만들고 `iptables -t raw -A PREROUTING -p icmp -j TRACE` 로 패킷 경로 추적
   ```bash
   sudo iptables -t raw -A PREROUTING -p icmp -j TRACE
   sudo xtables-monitor --trace     # nft 백엔드
   ```
2. DNAT 규칙으로 "가짜 Service" 만들기: `10.96.0.10:80` → pod-b
   ```bash
   sudo iptables -t nat -A PREROUTING -d 10.96.0.10 -p tcp --dport 80 -j DNAT --to-destination 10.244.1.3:80
   ```
3. `conntrack -L`, `conntrack -E`로 NAT 엔트리 생성/소멸 관찰
4. `iptables-save | wc -l`, `nft list ruleset` 비교

## 💥 Break-it
- `sysctl net.netfilter.nf_conntrack_max=100` 로 낮추고 부하 → `dmesg`에 `table full` 확인

## ✅ 확인 질문
- [ ] Service로 보낸 요청의 **응답**은 왜 다시 ClusterIP에서 온 것처럼 보이는가?
- [ ] conntrack 엔트리가 꽉 차면 어떤 연결부터 실패하는가?
