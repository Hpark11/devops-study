# 🧭 Master Plan — 시니어 DevOps 16주 학습 계획 (요약본)

> 원본: [Claude Docs 계획서](https://claude.ai/artifact/JvZvDAc4m6X46RYWtSXuEe) (2026-11-19 작성)
> 주제별 상세 내용은 각 `NN-topic/README.md`에 있다. 이 파일은 전체 뼈대다.

## 목표
16주(주 10~12시간) 동안 9개 기술을 **"패킷 하나가 Pod에서 나가 사용자 화면의 알람이 되기까지"** 한 줄로 꿰어 공부한다.
사용법이 아니라 **내부 동작, 장애 패턴, 트레이드오프를 설명하고 설계 의사결정을 내릴 수 있는 수준**이 목표다.

## 학습 원칙 (15년차 관점)
1. **한 레이어 아래까지 판다** — Istio → Envoy/xDS, CNI → eBPF·iptables·커널 라우팅, Prometheus → TSDB 블록
2. **장애로 배운다** — 기술마다 Break-it 실습 최소 2개
3. **비용·카디널리티를 숫자로 말한다** — 관측성은 비용 모델이 설계를 결정
4. **OSS vs SaaS를 같이 본다** — Prometheus/Loki/Grafana vs Datadog/Sentry를 같은 문제에 대비
5. **매주 산출물** — 다이어그램 1장 + 실습 커밋 + 1페이지 노트

## 로드맵 · 관문

| 단계 | 주차 | 주제 | 관문 (통과 기준) |
|---|:-:|---|---|
| 1. 네트워크 기반 | 1–2 | CNI (Linux 네트워킹 → Cilium/eBPF) | ◆ Pod→Service→다른 노드 Pod **패킷 경로를 끝까지 설명** (iptables판 / eBPF판) |
|  | 3 | CoreDNS |  |
| 2. 메시·워크플로 | 4–6 | Istio (sidecar → ambient) | ◆ **sidecar→ambient 전환 설계안** (단계·롤백 기준) |
|  | 7–8 | Argo Workflows |  |
| 3. 관측성 | 9–10 | 관측성 기초 + Prometheus |  |
|  | 11 | Loki + Alloy |  |
|  | 12 | Grafana |  |
|  | 13 | Datadog |  |
|  | 14 | Sentry | ◆ **OSS vs SaaS 도구 선택 ADR** |
| 4. 통합 | 15–16 | 캡스톤 · Game Day · 시스템 디자인 | 최종 산출물: 아키텍처 다이어그램, IaC, 포스트모템 3건, ADR 3건 |

## 주간 리듬
- 개념 읽기 3h → 실습 5h → 장애 재현 2h → 1페이지 노트 1h
- 평일 1.5h × 5 + 주말 3~4h
- 하루 진행: **예측 → 실행 → 망가뜨리기 → 자료 없이 설명**

## 환경
Mac(Apple Silicon, 10코어, 24GB) → Lima VM `devops`(Ubuntu 24.04, 4CPU/8GB/60GB) → Docker → kind.
캡스톤 즈음 VM을 6CPU/12GB로 확장.
