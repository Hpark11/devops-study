# 🐛 09. Sentry — 에러 트래킹 · 애플리케이션 모니터링

> **기간:** 14주차 (약 10~12시간)
> **핵심:** 인프라가 아니라 **코드 레벨의 실패**를 본다 · 개발자 워크플로와 self-hosted 운영 난이도 이해

---

## 🎯 학습 목표
- [ ] 이벤트 · 이슈 · grouping 모델을 설명하고 fingerprint를 조정한다
- [ ] 릴리스 · 소스맵을 CI와 연동한다
- [ ] self-hosted 아키텍처와 운영 부담을 SaaS와 비교한다
- [ ] Datadog / OTel과의 역할 분담을 정한다

## 🧠 핵심 개념
| 영역 | 내용 |
|---|---|
| 이벤트 모델 | event, issue(fingerprint grouping), breadcrumb, context, tag, release · environment |
| SDK | 에러 캡처, 트레이싱(transaction/span), 샘플링(`traces_sample_rate`, dynamic sampling), profiling, replay, logs |
| 릴리스 | sentry-cli 소스맵 · 디버그 심볼 업로드, suspect commit, release health(crash-free rate) |
| 알림 | issue alert vs metric alert, ownership(CODEOWNERS), Slack · PagerDuty · Jira |
| 아키텍처 | Relay(Rust, PII 스크러빙) → Kafka → consumers → Snuba/ClickHouse, Postgres, Redis, symbolicator |
| 연동 | trace context(sentry-trace, baggage)로 OTel · Datadog과 병행 |
| AI | Seer(근본 원인 · Autofix PR), Seer Agent(2026-04), Sentry MCP 서버 |

## 🛠️ 실습
| # | 실습 | 위치 | 완료 |
|:-:|---|---|:-:|
| 1 | Docker Compose로 self-hosted 설치, 서비스 구성도 작성 | `labs/01-self-hosted/` | ⬜ |
| 2 | React 프론트 + 백엔드에 SDK 적용, 분산 트레이스 연결 확인 | `labs/02-sdk-tracing/` | ⬜ |
| 3 | CI에서 릴리스 생성 · 소스맵 업로드 자동화 | `labs/03-release-ci/` | ⬜ |
| 4 | Relay PII 스크러빙 규칙 적용 | `labs/04-pii/` | ⬜ |

## 🔥 운영 포인트
- quota: rate limit, spike protection, inbound filter, 샘플링
- 잘못된 grouping(너무 많거나 너무 적은 issue) → fingerprint 커스텀
- self-hosted: 최소 4 CPU / 8 GB이지만 실제 운영은 훨씬 큼, 업그레이드 경로 준수, Kafka lag · ClickHouse 디스크, 라이선스(BUSL) 검토

## ❓ 자가 점검 질문
1. Datadog APM/Error Tracking이 있는데도 Sentry를 두는 이유는? 역할 분담은?
2. self-hosted Sentry와 SaaS의 TCO를 어떻게 비교하는가?

## 📚 자료
- [Sentry 문서](https://docs.sentry.io/) · [Self-hosted 문서](https://develop.sentry.dev/self-hosted/)
- [Seer Agent 발표](https://sentry.io/about/press-releases/sentry-launches-seer-agent/) · [Sentry 블로그](https://blog.sentry.io/)
