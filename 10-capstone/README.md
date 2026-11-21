# 🏁 10. 캡스톤 — 관측 가능한 메시 기반 플랫폼

> **기간:** 15~16주차 (약 20~24시간)
> **관문:** 9개 기술을 하나로 묶고, 장애를 일부러 내서 "어느 신호가 먼저 알려 주는가"를 끝까지 추적한다

---

## 🏗️ 캡스톤 구성

```
 ┌──────────── Cluster A ────────────┐     ┌──────────── Cluster B ────────────┐
 │ Cilium (KPR + Hubble)             │     │ Cilium                            │
 │ NodeLocal DNSCache                │◀───▶│ Istio ambient (multicluster)      │
 │ Istio ambient + waypoint          │     │ OTel Demo 일부 서비스               │
 │ OTel Demo 앱 · Argo Workflows 배치  │     │                                   │
 └──────────────┬────────────────────┘     └──────────────┬────────────────────┘
                │ OTLP                                     │
         ┌──────▼──────────────── OTel Collector ──────────▼─────┐
         │  metrics → Prometheus(+Thanos/Mimir)  logs → Alloy → Loki │
         │  traces → Tempo      errors → Sentry   fan-out → Datadog │
         └──────────────────────────┬────────────────────────────┘
                                    ▼
                    Grafana (SLO 대시보드 · 알람, as Code)
```

| # | 구성 | 완료 |
|:-:|---|:-:|
| 1 | Cilium(kube-proxy replacement + Hubble) 클러스터 2개, NodeLocal DNSCache | ⬜ |
| 2 | Istio ambient + waypoint, 클러스터 간 트래픽 | ⬜ |
| 3 | [OpenTelemetry Demo](https://opentelemetry.io/docs/demo/)를 OTel로 계측 | ⬜ |
| 4 | 배치 작업은 Argo Workflows, 컨트롤러 메트릭 수집 | ⬜ |
| 5 | Prometheus · Alloy→Loki · Tempo · Sentry | ⬜ |
| 6 | OTel Collector에서 Datadog으로도 fan-out해 비교 | ⬜ |
| 7 | SLO 대시보드 · burn-rate 알람을 Grafana에 코드로 배포 | ⬜ |

## 💥 Game Day 시나리오
> 각 시나리오마다 [포스트모템](../00-guide/templates/postmortem.md) 작성 · **어느 신호가 먼저? MTTD / MTTR은?**

| # | 시나리오 | 예상 첫 신호 | 실제 첫 신호 | MTTD | 완료 |
|:-:|---|---|---|:-:|:-:|
| 1 | CoreDNS upstream 장애 | | | | ⬜ |
| 2 | NetworkPolicy 오타로 특정 서비스 차단 | | | | ⬜ |
| 3 | Istio 인증서 / mTLS 불일치 | | | | ⬜ |
| 4 | Prometheus 카디널리티 폭발 → OOM | | | | ⬜ |
| 5 | Loki ingester 장애 → 로그 유실 범위 | | | | ⬜ |
| 6 | Argo 대규모 fan-out → API 서버 압박 | | | | ⬜ |

## 🧩 시스템 디자인 연습 (화이트보드 45분)
| # | 문제 | 노트 | 완료 |
|:-:|---|---|:-:|
| 1 | 서비스 1,000개 · 클러스터 20개 · 리전 3개 글로벌 관측성 플랫폼 (비용 상한 포함) | `notes/sd-01-observability.md` | ⬜ |
| 2 | 단일 → 멀티클러스터 서비스 메시 마이그레이션 계획 | `notes/sd-02-mesh-migration.md` | ⬜ |
| 3 | 하루 로그 50TB, 보존 30일, 검색 SLA 10초 로깅 시스템 | `notes/sd-03-logging.md` | ⬜ |
| 4 | ML 학습·추론 파이프라인 (Argo + GPU + 메시의 추론 라우팅) | `notes/sd-04-ml-platform.md` | ⬜ |
| 5 | Datadog ↔ OSS 스택 전환 의사결정 | `notes/sd-05-vendor-decision.md` | ⬜ |

## 📦 최종 산출물
- [ ] 아키텍처 다이어그램
- [ ] IaC 저장소 (`labs/`)
- [ ] Game Day 포스트모템 3건 이상
- [ ] 도구 선택 [ADR](../00-guide/templates/adr.md) 3건
