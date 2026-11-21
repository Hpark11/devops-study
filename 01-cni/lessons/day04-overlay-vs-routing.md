# Day 4 — Overlay(VXLAN) vs Native Routing · MTU

> ⏱️ 2시간 · 🎯 노드 간 Pod 통신의 3가지 방식과 트레이드오프를 설명할 수 있다

## 💡 개념 요약

| 방식 | 원리 | 장점 | 단점 | 예 |
|---|---|---|---|---|
| **Overlay** (VXLAN/Geneve) | Pod 패킷을 UDP로 캡슐화 | 언더레이 네트워크 무관 | 오버헤드 50B, MTU 축소, 디버깅 어려움 | Flannel, Calico VXLAN, Cilium 기본 |
| **Native routing** (BGP/static) | 노드가 podCIDR 라우트를 광고 | 성능, 투명성 | 언더레이가 라우트를 받아야 함 | Calico BGP, Cilium native |
| **VPC 네이티브** | Pod가 VPC IP를 직접 받음 | 클라우드 네트워크와 일체 | IP 고갈, ENI 한도 | AWS VPC CNI, Azure CNI, GKE |

```
VXLAN 패킷 = [외부 Eth][외부 IP: nodeA→nodeB][UDP 8472/4789][VXLAN hdr][내부 Eth][내부 IP: podA→podB][payload]
            └──────────────── 50 bytes overhead ────────────────┘
```

## 🛠️ 실습
1. kind + Calico(VXLAN 모드) 설치
2. 노드 간 Pod ping 하며 노드 eth0에서 캡처
   ```bash
   tcpdump -ni eth0 udp port 4789 -vv
   ```
   Wireshark로 열어 내부/외부 헤더 확인
3. Calico를 BGP 모드로 바꿨을 때 `ip route`가 어떻게 바뀌는지 비교
4. Pod와 노드의 MTU 확인 (`ip link`), 1500 − 50 = 1450 계산 확인

## ✅ 확인 질문
- [ ] 온프레미스 L3 패브릭과 AWS 환경에서 각각 어떤 방식을 고르겠는가?
- [ ] Jumbo frame(9001)을 쓰는 AWS에서 overlay MTU는 얼마로 잡는가?
