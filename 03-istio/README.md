# 🕸️ 03. Istio — 서비스 메시 (sidecar → ambient)

> **기간:** 4~6주차 (약 30~36시간)
> **관문:** 2,000개 서비스 조직의 sidecar → ambient 전환 설계안(단계·롤백 기준)을 쓸 수 있다

---

## 🎯 학습 목표
- [ ] istiod ↔ Envoy 사이의 xDS 흐름을 설명하고 `config_dump`를 읽는다
- [ ] sidecar와 ambient(ztunnel + waypoint)의 트래픽 경로·비용·한계를 비교한다
- [ ] mTLS, AuthorizationPolicy, Gateway API로 보안·트래픽을 제어한다
- [ ] revision 기반 canary upgrade와 멀티클러스터를 구성한다

## 🗓️ 주차 계획
| 주차 | 주제 | 완료 |
|:-:|---|:-:|
| 4 | 컨트롤 플레인 · xDS · Envoy 내부 · sidecar 모델 | ⬜ |
| 5 | ambient(ztunnel · HBONE · waypoint) · 보안(mTLS · AuthZ) | ⬜ |
| 6 | 트래픽 관리 · Gateway API · 멀티클러스터 · 업그레이드 | ⬜ |

## 🧠 핵심 개념
| 영역 | 내용 |
|---|---|
| 컨트롤 플레인 | istiod, xDS(LDS/RDS/CDS/EDS/SDS), push · debounce, `istioctl proxy-status` |
| Envoy | listener → filter chain → route → cluster → endpoint, outlier detection, circuit breaking, retry budget |
| Sidecar | istio-init / istio-cni의 iptables REDIRECT, 15001/15006, native sidecar, Job 종료 문제 |
| Ambient | ztunnel(노드당 L4, Rust, HBONE), waypoint(L7), 재시작 없는 편입 `istio.io/dataplane-mode=ambient` |
| 보안 | SPIFFE ID, 인증서 로테이션, PeerAuthentication, AuthorizationPolicy 평가 순서(CUSTOM → DENY → ALLOW) |
| 트래픽 | VirtualService/DestinationRule vs Gateway API(HTTPRoute), 카나리·미러링·fault injection, Inference Extension |
| 멀티클러스터 | primary-remote, multi-primary, multi-network(east-west gateway) |
| 확장 | WasmPlugin, EnvoyFilter의 위험성, TrafficExtension API(1.30) |

## 🛠️ 실습
| # | 실습 | 위치 | 완료 |
|:-:|---|---|:-:|
| 1 | sidecar 모드 Bookinfo → `istioctl proxy-config`로 listener/route/cluster 해부 | `labs/01-sidecar-anatomy/` | ⬜ |
| 2 | 같은 앱을 ambient로 전환, waypoint 추가 전후 L7 정책·리소스 비교 | `labs/02-ambient/` | ⬜ |
| 3 | revision 기반 canary upgrade | `labs/03-canary-upgrade/` | ⬜ |
| 4 | 💥 fault injection + outlier detection으로 장애 격리 | `labs/04-resilience/` | ⬜ |
| 5 | kind 2개로 multi-primary 구성 | `labs/05-multicluster/` | ⬜ |

## 🔥 운영 포인트
- 업그레이드: revision · tag, 지원 K8s 버전 확인 (1.30 → K8s 1.32~1.36)
- istiod 메모리 · push 폭주 → `Sidecar` 리소스로 설정 범위 제한
- Envoy response flag(UC/UF/NR/UH) 해석, mTLS 불일치, idle timeout
- 비용: sidecar N개 vs ztunnel + waypoint

## ❓ 자가 점검 질문
1. ambient에서 L7 AuthorizationPolicy를 걸었는데 동작하지 않는다. 가장 먼저 의심할 것은?
2. sidecar → ambient 전환 계획의 단계와 롤백 기준은?
3. Istio와 Cilium Service Mesh를 언제 각각 선택하는가?

## 📚 자료
- [Istio 문서](https://istio.io/latest/docs/) · [Istio 1.31 릴리스](https://istio.io/news/releases/1.31.x/announcing-1.31/)
- [Envoy 아키텍처 개요](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/arch_overview)
- 📕 *Istio in Action*
