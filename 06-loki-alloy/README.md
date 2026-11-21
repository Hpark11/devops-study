# 🪵 06. Loki + Grafana Alloy — 로그

> **기간:** 11주차 (약 10~12시간)
> **핵심:** "레이블만 인덱싱, 본문은 오브젝트 스토리지"라는 비용 모델 · **Promtail EOL(2026-03-02) → Alloy 전환**

---

## 🎯 학습 목표
- [ ] Loki의 쓰기/읽기 경로와 배포 모드를 설명한다
- [ ] 레이블과 structured metadata를 올바르게 설계한다
- [ ] LogQL로 검색 · 메트릭 쿼리 · recording rule을 작성한다
- [ ] Promtail 설정을 Alloy로 이전한다

## 🧠 핵심 개념
| 영역 | 내용 |
|---|---|
| 쓰기 경로 | distributor → ingester(WAL, chunk) → object storage |
| 읽기 경로 | query-frontend(split · cache) → querier → index-gateway, compactor(retention · delete) |
| 배포 모드 | monolithic / simple scalable(read · write · backend) / microservices |
| 스키마 | v13 + TSDB 인덱스, **structured metadata**(OTLP 네이티브 수신 기반), bloom |
| 레이블 설계 | stream 수 = 레이블 조합 → 고카디널리티 값(trace_id, user_id)은 structured metadata로 |
| LogQL | stream selector · line filter · parser(json/logfmt/pattern) · `rate` · `count_over_time` · `quantile_over_time` |
| 멀티테넌시 | `X-Scope-OrgID`, per-tenant limit |
| Alloy | 컴포넌트 파이프라인(discovery → relabel → `loki.process` → `loki.write`), OTel Collector 호환 |

## 🛠️ 실습
| # | 실습 | 위치 | 완료 |
|:-:|---|---|:-:|
| 1 | ⭐ 기존 [loki-prometheus-grafana 튜토리얼](../loki-prometheus-grafana-docker-logging-monitoring-tutorial/)의 `promtail.yaml`을 `alloy convert`로 변환 · diff 검토 | `labs/01-promtail-to-alloy/` | ⬜ |
| 2 | K8s에 simple scalable Loki + MinIO + Alloy DaemonSet | `labs/02-k8s-loki/` | ⬜ |
| 3 | 💥 request_id를 레이블로 넣어 stream 폭발 재현 → structured metadata로 수정 | `labs/03-stream-explosion/` | ⬜ |
| 4 | 5xx 비율 recording rule → Prometheus remote write → 알람 | `labs/04-log-to-metric/` | ⬜ |

```bash
alloy convert --source-format=promtail --output=config.alloy promtail.yaml
```

## 🔥 운영 포인트
- "too many outstanding requests", rate/stream limit, ingester OOM
- 넓은 시간 범위 쿼리 → 캐시 · 병렬화 튜닝, 메타 모니터링
- 3.7 breaking change: parsed label이 structured metadata를 덮어쓰지 않음 · Helm 차트는 `grafana-community/helm-charts`

## ❓ 자가 점검 질문
1. Loki vs Elasticsearch/OpenSearch vs ClickHouse 기반 로그 저장소의 비용·검색 트레이드오프는?
2. 하루 10TB 로그를 받는 Loki의 레이블 정책과 retention을 어떻게 설계하는가?

## 📚 자료
- [Loki 문서](https://grafana.com/docs/loki/latest/) · [레이블 모범 사례](https://grafana.com/docs/loki/latest/get-started/labels/bp-labels/)
- [Promtail → Alloy 이전](https://grafana.com/docs/alloy/latest/set-up/migrate/from-promtail/) · [Loki 3.7 릴리스 노트](https://grafana.com/docs/loki/latest/release-notes/v3-7/)
