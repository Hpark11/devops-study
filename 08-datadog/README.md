# 🐶 08. Datadog — SaaS 관측성 플랫폼

> **기간:** 13주차 (약 10~12시간)
> **핵심:** 기능보다 **과금 모델과 태깅 전략**이 성패를 가른다

---

## 🎯 학습 목표
- [ ] Agent 구성 요소와 Kubernetes 배포 방식을 설명한다
- [ ] Unified Service Tagging으로 메트릭 · 트레이스 · 로그를 연결한다
- [ ] 청구서가 어디서 커지는지 알고 줄이는 방법을 설계한다
- [ ] Datadog vs LGTM 자체 운영 vs 혼합의 판단 기준을 세운다

## 🧠 핵심 개념
| 영역 | 내용 |
|---|---|
| Agent | core · trace-agent · process-agent · system-probe(eBPF NPM/USM), Cluster Agent(External Metrics → HPA), Operator |
| 태깅 | **Unified Service Tagging**(`env` · `service` · `version`), Autodiscovery 어노테이션 |
| APM | ddtrace 자동 계측, ingestion control vs retention filter, OTLP 수신 |
| 로그 | pipeline · processor, index vs archive vs Flex Logs, Logging without Limits, Log-to-metric |
| 메트릭 | custom metric 과금(이름 × 태그 값 조합), Metrics without Limits, distribution |
| 알림/SLO | metric · anomaly · forecast · composite monitor, SLO, Incident, Watchdog |
| 2026 변화 | DASH 2026: Bits AI 자율 탐지·조사·조치, Bits Code, MCP Apps, Agent Observability |
| 기타 | RUM, Synthetics, CSM/ASM, CI Visibility, LLM Observability |

## 💰 비용 폭발 패턴
| 원인 | 대응 |
|---|---|
| 고카디널리티 태그(pod_name, user_id) | Metrics without Limits로 태그 허용 목록 |
| 로그 전량 인덱싱 | exclusion filter + archive + Flex Logs |
| APM 호스트 · 스팬 과다 | ingestion sampling, retention filter |
| 팀별 사용량 불투명 | Usage Attribution, 팀 태그 강제 |

## 🛠️ 실습 (무료 체험 계정)
| # | 실습 | 위치 | 완료 |
|:-:|---|---|:-:|
| 1 | Helm/Operator로 Agent 배포, USM · NPM 켜고 서비스 맵 확인 | `labs/01-agent/` | ⬜ |
| 2 | 같은 앱을 ddtrace와 OTel SDK로 각각 계측해 비교 ([OpenTelemetry](../OpenTelemetry/) 앱 활용) | `labs/02-ddtrace-vs-otel/` | ⬜ |
| 3 | 로그 파이프라인 + exclusion filter + archive, 인덱싱 비용 계산 | `labs/03-logs-cost/` | ⬜ |
| 4 | Terraform으로 SLO + burn-rate monitor | `labs/04-terraform-slo/` | ⬜ |

## ❓ 자가 점검 질문
1. Datadog 청구서가 연 30% 늘었다. 어디부터 보고 어떻게 줄이는가?
2. Datadog 전면 도입 vs LGTM 자체 운영 vs 혼합 — 조직 규모 · 인력 · 데이터량별 판단 기준은?

## 📚 자료
- [Datadog 문서](https://docs.datadoghq.com/) · [Unified Service Tagging](https://docs.datadoghq.com/getting_started/tagging/unified_service_tagging/)
- [Custom metrics 과금](https://docs.datadoghq.com/account_management/billing/custom_metrics/) · [DASH 2026 정리](https://www.datadoghq.com/blog/dash-2026-new-feature-roundup-keynote/)
- Datadog Learning Center (무료 강좌)
