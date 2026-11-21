# 🌐 01. CNI — Kubernetes 네트워킹의 바닥

> **기간:** 1~2주차 (약 20~24시간)
> **관문:** "Pod A의 패킷이 다른 노드의 Service 뒤 Pod B에 닿기까지 거치는 모든 지점"을 iptables 버전과 eBPF 버전으로 설명할 수 있다

---

## 🎯 학습 목표

- [ ] CNI가 결국 **"veth 만들고, IP 주고, 라우팅 거는 실행 파일"** 임을 직접 구현해서 이해한다
- [ ] Overlay(VXLAN)와 native routing, 클라우드 VPC CNI의 차이와 트레이드오프를 설명한다
- [ ] kube-proxy(iptables/IPVS/nftables)와 Cilium eBPF 서비스 로드밸런싱을 비교한다
- [ ] NetworkPolicy가 어디서 어떻게 집행되는지, drop 원인을 Hubble로 추적할 수 있다
- [ ] MTU, conntrack, IP 고갈 등 대표 장애를 재현하고 탐지 방법을 안다

## 🗓️ 일정

### 1주차 — CNI 없이 Pod 네트워크를 손으로 만들기

| Day | 주제 | 가이드 | 완료 |
|:---:|---|---|:---:|
| 1 | netns · veth · bridge | [day01](./lessons/day01-netns-veth-bridge.md) | ⬜ |
| 2 | 라우팅 · iptables 체인 · conntrack | [day02](./lessons/day02-routing-iptables-conntrack.md) | ⬜ |
| 3 | CNI 스펙 + **bash CNI 플러그인 직접 구현** ⭐ | [day03](./lessons/day03-cni-spec-bash-plugin.md) | ⬜ |
| 4 | Overlay(VXLAN) vs Native Routing · MTU | [day04](./lessons/day04-overlay-vs-routing.md) | ⬜ |
| 5 | Service · kube-proxy · 💥 MTU 장애 재현 | [day05](./lessons/day05-service-kube-proxy.md) | ⬜ |

### 2주차 — Cilium과 eBPF로 다시 보기

| Day | 주제 | 가이드 | 완료 |
|:---:|---|---|:---:|
| 6 | eBPF 기초 (XDP · tc · map) | [day06](./lessons/day06-ebpf-basics.md) | ⬜ |
| 7 | Cilium 설치 · kube-proxy replacement | [day07](./lessons/day07-cilium-install.md) | ⬜ |
| 8 | Service LB 벤치마크 (iptables vs eBPF) | [day08](./lessons/day08-service-lb-benchmark.md) | ⬜ |
| 9 | NetworkPolicy · L7/FQDN · Hubble | [day09](./lessons/day09-networkpolicy-hubble.md) | ⬜ |
| 10 | 암호화(WireGuard) · 클라우드 CNI · 정리 | [day10](./lessons/day10-encryption-cloud-cni.md) | ⬜ |

## 📦 산출물

| 산출물 | 위치 | 완료 |
|---|---|:---:|
| 패킷 경로 다이어그램 (iptables 버전 / eBPF 버전) | `notes/packet-path.md` | ⬜ |
| bash CNI 플러그인 | `labs/03-bash-cni/` | ⬜ |
| Service LB 벤치마크 스크립트 + 결과 | `labs/08-lb-benchmark/` | ⬜ |
| 1페이지 노트: "5,000노드 클러스터의 CNI 선택" | `notes/cni-selection.md` | ⬜ |

## 🔥 운영·장애 포인트 (시니어 체크리스트)

| 장애 패턴 | 증상 | 확인 방법 |
|---|---|---|
| MTU 불일치 | 작은 요청은 되는데 큰 응답만 멈춤 | `ping -M do -s <size>`, `tcpdump`로 ICMP frag-needed |
| conntrack 포화 | 랜덤한 연결 실패, `nf_conntrack: table full` | `conntrack -S`, `dmesg` |
| IP 고갈 | Pod가 `ContainerCreating`에서 멈춤 | CNI 로그, IPAM 상태, ENI 한도 |
| CNI 업그레이드 | 롤링 중 일부 노드 통신 단절 | 노드 풀 단위 교체 전략 |
| 정책 오타 | 특정 서비스만 timeout | `hubble observe --verdict DROPPED` |

## ❓ 자가 점검 질문

1. Pod A → 다른 노드 Service로 가는 패킷은 **어느 hook에서 DNAT** 되는가? iptables 모드와 eBPF 모드 각각 설명하라.
2. VXLAN overlay에서 MTU를 1450으로 잡는 이유는?
3. NetworkPolicy가 하나도 없을 때와 하나라도 선택될 때 기본 동작은 어떻게 달라지는가?
4. 5,000노드 클러스터에서 CNI를 고를 때 평가 기준 5가지는?
5. kube-proxy 없이 Cilium이 Service를 처리하면 conntrack은 어디서 관리되는가?

## 📚 자료

- [CNI 스펙](https://github.com/containernetworking/cni/blob/main/SPEC.md) · [CNI reference plugins](https://github.com/containernetworking/plugins)
- [Cilium 문서](https://docs.cilium.io/) · [Isovalent Labs (무료 실습)](https://isovalent.com/labs/)
- [Kubernetes Networking Model](https://kubernetes.io/docs/concepts/services-networking/)
- 📕 *Learning eBPF* — Liz Rice
