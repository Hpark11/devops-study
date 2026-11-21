# 📈 05. 관측성 기초 + Prometheus

> **기간:** 9~10주차 (약 20~24시간)
> **핵심:** 관측성 설계 원칙을 먼저 세우고, Prometheus 3.x(OTLP · native histogram · UTF-8)를 내부 구조까지 이해한다

---

## 🗓️ 주차 계획
| 주차 | 주제 | 완료 |
|:-:|---|:-:|
| 9 | 관측성 기초 (신호 · SLO · OTel · 카디널리티) + PromQL | ⬜ |
| 10 | TSDB 내부 · Alertmanager · 장기 보관(Thanos/Mimir) | ⬜ |

## 🧠 관측성 기초
| 주제 | 내용 |
|---|---|
| 신호 4종 | metrics · logs · traces · profiles, 비용 구조, exemplar로 연결 |
| 방법론 | RED · USE · Four Golden Signals |
| SLO | SLI · SLO · error budget, **multi-window multi-burn-rate 알람** |
| OpenTelemetry | SDK, Collector(receiver/processor/exporter), semantic conventions, tail sampling |
| 카디널리티 | 비용 = series 수 × 보존 기간 × 해상도 |

## 🧠 Prometheus 핵심 개념
| 영역 | 내용 |
|---|---|
| 수집 | pull 모델, kubernetes_sd, `relabel_configs` vs `metric_relabel_configs` |
| TSDB | head block · WAL · mmap chunk · compaction · 2h 블록, out-of-order, 메모리 = active series |
| PromQL | `rate` / `irate` / `increase`, `by` / `without`, vector matching, `histogram_quantile` 오차, recording rule |
| 히스토그램 | classic vs **native**(지수 버킷, series 1개, 3.8 stable · 3.9부터 `scrape_native_histograms`) |
| Alertmanager | grouping · inhibition · silence · routing tree · HA gossip |
| 확장 | Thanos vs Mimir vs VictoriaMetrics, Remote Write 2.0, Prometheus Operator, Agent 모드 |
| OTel 연동 | OTLP 수신 `--web.enable-otlp-receiver` → `/api/v1/otlp/v1/metrics` |

## 🛠️ 실습
| # | 실습 | 위치 | 완료 |
|:-:|---|---|:-:|
| 0 | 기존 [prometheus-docker-compose-main](../prometheus-docker-compose-main/) 복습 | — | ⬜ |
| 1 | kube-prometheus-stack + `promtool tsdb analyze`로 카디널리티 원인 찾기 | `labs/01-cardinality/` | ⬜ |
| 2 | native histogram 노출, classic 대비 series 수 비교 | `labs/02-native-histogram/` | ⬜ |
| 3 | OTel SDK → Prometheus OTLP 직접 수신 ([OpenTelemetry](../OpenTelemetry/) 앱 활용) | `labs/03-otlp/` | ⬜ |
| 4 | SLO 99.9% burn-rate 알람 (Sloth / Pyrra) | `labs/04-slo/` | ⬜ |
| 5 | Thanos 또는 Mimir로 2개 클러스터 글로벌 뷰 | `labs/05-global-view/` | ⬜ |

## 🔥 운영 포인트
- 💥 카디널리티 폭발(user_id, URL path) → OOM, `prometheus_tsdb_head_series` 감시
- 증상 기반 알람, SLO 기반 페이징으로 알람 피로도 줄이기
- LTS 운영: 3.13 LTS (2027-07까지 지원)

## ❓ 자가 점검 질문
1. `rate(x[1m])`이 빈 결과를 주는 이유는? scrape interval과 range의 관계는?
2. 1천만 active series를 처리해야 한다면 어떤 아키텍처를, 왜 고르는가?

## 📚 자료
- [Prometheus 문서](https://prometheus.io/docs/) · [OTLP 가이드](https://prometheus.io/docs/guides/opentelemetry/)
- [Google SRE Workbook](https://sre.google/workbook/table-of-contents/)
- 📕 *Prometheus: Up & Running* 2판 · 📕 *Observability Engineering*
