# 🧭 Senior DevOps Study

> 15년차 DevOps 관점으로 **Kubernetes 네트워킹 · 워크플로 · 관측성** 9개 기술을 16주 동안 깊게 공부하는 저장소
>
> 📄 상세 계획서: [시니어 DevOps 학습 계획서 (Claude Docs)](https://claude.ai/artifact/JvZvDAc4m6X46RYWtSXuEe)
> 🗓️ 기준일: 2026-11-19

---

## 🗺️ 로드맵

```
 1~3주            4~8주                 9~14주                          15~16주
┌────────────┐  ┌──────────────────┐  ┌───────────────────────────┐  ┌──────────┐
│ 네트워크 기반 │→ │ 메시 · 워크플로      │→ │ 관측성                        │→ │ 통합      │
│ CNI        │  │ Istio            │  │ Prometheus · Loki · Grafana │  │ 캡스톤     │
│ CoreDNS    │  │ Argo Workflows   │  │ Datadog · Sentry            │  │ Game Day │
└────────────┘  └──────────────────┘  └───────────────────────────┘  └──────────┘
      ◆ 관문 1             ◆ 관문 2                     ◆ 관문 3
 패킷 경로 끝까지 설명   ambient 전환 설계안          OSS vs SaaS ADR 작성
```

## ✅ 진행 현황

| 주차 | 디렉토리 | 주제 | 상태 |
|:---:|---|---|:---:|
| 0 | [00-guide/day00](./00-guide/day00-environment-setup.md) | 실습 환경 준비 (Lima VM · kind) | ⬜ |
| 1–2 | [01-cni](./01-cni/) | CNI · Linux 네트워킹 · Cilium/eBPF | ⬜ |
| 3 | [02-coredns](./02-coredns/) | CoreDNS · 클러스터 DNS | ⬜ |
| 4–6 | [03-istio](./03-istio/) | Istio (sidecar / ambient) · Envoy | ⬜ |
| 7–8 | [04-argo-workflows](./04-argo-workflows/) | Argo Workflows · Argo Events | ⬜ |
| 9–10 | [05-prometheus](./05-prometheus/) | 관측성 기초 · Prometheus · OTel | ⬜ |
| 11 | [06-loki-alloy](./06-loki-alloy/) | Loki · Grafana Alloy | ⬜ |
| 12 | [07-grafana](./07-grafana/) | Grafana · Observability as Code | ⬜ |
| 13 | [08-datadog](./08-datadog/) | Datadog | ⬜ |
| 14 | [09-sentry](./09-sentry/) | Sentry | ⬜ |
| 15–16 | [10-capstone](./10-capstone/) | 캡스톤 · Game Day · 시스템 디자인 | ⬜ |

> 상태 표기: ⬜ 시작 전 · 🟨 진행 중 · ✅ 완료

## 📁 디렉토리 구조

```
DevOps/
├── README.md                 ← 지금 보고 있는 인덱스
├── 00-guide/                 ← 학습 방법, 버전 현황, 템플릿
│   ├── study-method.md
│   ├── versions-2026-11.md
│   └── templates/            ← 주간 노트 · 실습 리포트 · 포스트모템 · ADR
├── 01-cni/ … 10-capstone/    ← 주제별 학습 공간
│   ├── README.md             ← 목표 · 일정 · 체크리스트 · 점검 질문 · 자료
│   ├── lessons/              ← 일차별 가이드 (01-cni부터)
│   ├── notes/                ← 개념 정리 노트
│   └── labs/                 ← 실습 코드 · 설정 · 결과
└── (기존 실습 폴더들)          ← 아래 표 참고
```

## 🧪 기존 실습 자료 (재활용)

| 폴더 | 내용 | 연결 주제 |
|---|---|---|
| [prometheus-docker-compose-main](./prometheus-docker-compose-main/) | FastAPI + Prometheus + Grafana | 05-prometheus |
| [loki-prometheus-grafana-docker-logging-monitoring-tutorial](./loki-prometheus-grafana-docker-logging-monitoring-tutorial/) | Loki + Promtail + MinIO + Alertmanager | 06-loki-alloy (Promtail → Alloy 전환 실습에 활용) |
| [distributed-tracing-alloy-grafana-tempo-main](./distributed-tracing-alloy-grafana-tempo-main/) | Alloy + Tempo 분산 트레이싱 | 07-grafana, 10-capstone |
| [OpenTelemetry](./OpenTelemetry/) | Spring Boot order / invoice + OTel Collector | 05-prometheus, 10-capstone |

## 🔁 매주 루틴

1. 📖 **개념 읽기** 3h — 공식 문서 + 릴리스 노트
2. 🛠️ **실습** 5h — `labs/`에 커밋
3. 💥 **장애 재현** 2h — 일부러 망가뜨리고 증상 기록
4. 📝 **1페이지 노트** 1h — `notes/`에 [주간 노트 템플릿](./00-guide/templates/weekly-note.md)으로 정리
