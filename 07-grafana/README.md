# 📊 07. Grafana — 시각화 · 알림 · Observability as Code

> **기간:** 12주차 (약 10~12시간)
> **핵심:** 대시보드 만드는 법이 아니라 **수백 팀이 쓰는 플랫폼을 코드로 운영**하는 법

---

## 🎯 학습 목표
- [ ] 메트릭 → 트레이스 → 로그로 이어지는 drill-down 대시보드를 설계한다
- [ ] Grafana Alerting 구조를 이해하고 Alertmanager와의 역할을 나눈다
- [ ] 대시보드 · 알람을 코드(Jsonnet / Terraform / Git Sync)로 관리한다

## 🧠 핵심 개념
| 영역 | 내용 |
|---|---|
| 기본 | 데이터소스, 변수(query/custom/interval), transformations, 패널별 쿼리 비용 |
| 설계 | RED/USE 레이아웃, 서비스 개요 → 인스턴스 → 로그/트레이스, exemplar · data link |
| 알림 | alert rule · contact point · notification policy (unified alerting) |
| as Code | 프로비저닝 YAML, Terraform provider, Grafonnet/Jsonnet, Foundation SDK, **Git Sync(13 GA)** |
| 13.x 변화 | dynamic dashboards(schema v2) GA, suggested dashboards, Grafana Assistant |
| 운영 | HA(외부 DB), 조직/팀/폴더 권한, SSO · RBAC, 플러그인 관리 |
| LGTM | Mimir · Loki · Tempo · Pyroscope |

## 🛠️ 실습
| # | 실습 | 위치 | 완료 |
|:-:|---|---|:-:|
| 1 | 서비스 RED 대시보드를 Jsonnet 또는 Terraform으로 작성, PR로 배포 | `labs/01-dashboard-as-code/` | ⬜ |
| 2 | 기존 [distributed-tracing-alloy-grafana-tempo](../distributed-tracing-alloy-grafana-tempo-main/) 확장: exemplar → 트레이스 → 로그 drill-down | `labs/02-drilldown/` | ⬜ |
| 3 | Grafana Alerting으로 SLO 알람 → Slack 라우팅 | `labs/03-alerting/` | ⬜ |
| 4 | Git Sync로 대시보드 양방향 동기화 | `labs/04-git-sync/` | ⬜ |

## 🔥 운영 포인트
- 무거운 대시보드가 Prometheus/Loki를 두드리는 문제 → 쿼리 제한, recording rule
- 대시보드 난립 · 소유권 → 폴더 규칙, 태그, 정기 정리
- 메이저 업그레이드 시 schema v2 마이그레이션 · Git Sync 주의사항

## ❓ 자가 점검 질문
1. 300개 팀이 쓰는 Grafana에서 대시보드 품질과 쿼리 부하를 어떻게 통제하는가?
2. 알람은 Grafana Alerting과 Prometheus Alertmanager 중 어디에 두는가?

## 📚 자료
- [Grafana 문서](https://grafana.com/docs/grafana/latest/) · [Grafana 13 발표](https://grafana.com/blog/grafana-13-release-all-the-latest-features)
- [Observability as Code](https://grafana.com/docs/grafana/latest/as-code/)
