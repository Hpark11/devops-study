# Day 10 — 암호화(WireGuard) · 클라우드 CNI · 2주 정리

> ⏱️ 3시간 · 🎯 관문 통과: 패킷 경로를 끝까지 설명하고 CNI 선택 기준을 문서로 남긴다

## 🛠️ 실습
1. WireGuard 암호화
   ```bash
   cilium upgrade --set encryption.enabled=true --set encryption.type=wireguard
   cilium-dbg encrypt status
   ```
   - 켜기 전/후 `iperf3` throughput, CPU 비교 → `labs/10-encryption/RESULT.md`
   - 노드 eth0에서 `tcpdump`로 평문이 안 보이는지 확인
2. (이론) 클라우드 CNI 정리

| 항목 | AWS VPC CNI | GKE Dataplane V2 | Azure CNI Overlay |
|---|---|---|---|
| Pod IP | VPC IP (ENI secondary IP / prefix) | alias IP | overlay |
| 데이터패스 | iptables / eBPF 선택 | Cilium 기반 | Cilium 옵션 |
| 대표 이슈 | IP 고갈, ENI당 IP 한도 → prefix delegation | — | — |

## 🏁 관문 체크
- [ ] `notes/packet-path.md`: Pod A → Service → 다른 노드 Pod B 경로를 **iptables 버전 / eBPF 버전** 두 장으로 그렸다
- [ ] `notes/cni-selection.md`: "5,000노드 클러스터에서 CNI를 고른다면?"에 1페이지로 답했다
  - 평가 축: 성능, 규모(IPAM·정책 수), 관측성, 보안(암호화·L7), 운영 성숙도, 클라우드 통합, 팀 역량
- [ ] README의 자가 점검 질문 5개에 막힘없이 답할 수 있다

➡️ 다음: [02-coredns](../../02-coredns/)
