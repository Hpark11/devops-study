# 🐙 04. Argo Workflows — Kubernetes 네이티브 워크플로

> **기간:** 7~8주차 (약 20~24시간)
> **핵심:** 문법보다 **컨트롤러가 etcd · API 서버에 주는 부하**와 대규모 fan-out의 한계를 이해한다

---

## 🎯 학습 목표
- [ ] 컨트롤러 reconcile 구조와 CRD 관계를 설명한다
- [ ] DAG · fan-out · 아티팩트 · 재시도 · 동시성 제어를 실전 수준으로 쓴다
- [ ] 대규모 워크플로의 병목(etcd 객체 크기, API QPS)을 진단하고 튜닝한다
- [ ] Argo Workflows / Airflow / Tekton / Temporal 선택 기준을 말한다

## 🧠 핵심 개념
| 영역 | 내용 |
|---|---|
| 아키텍처 | workflow-controller, argo-server(UI/API · SSO), executor(emissary) |
| CRD | Workflow, WorkflowTemplate, ClusterWorkflowTemplate, CronWorkflow |
| 템플릿 | container · script · resource · suspend · http · plugin / steps vs DAG |
| 흐름 제어 | 인자·출력, `withItems`/`withParam`, `when`, exit handler |
| 아티팩트 | S3/GCS/MinIO, 아티팩트 드라이버 플러그인(4.0), artifact GC |
| 동시성 | parallelism, semaphore/mutex, priority, retryStrategy, memoization |
| 상태 보존 | node status offloading, archive(Postgres/MySQL), TTL · podGC |
| 연계 | Argo Events(트리거), Argo CD(템플릿 GitOps), Kubeflow Pipelines |

## 🛠️ 실습
| # | 실습 | 위치 | 완료 |
|:-:|---|---|:-:|
| 1 | DAG ETL: 다운로드 → 병렬 변환 1,000개 → 집계 (MinIO 아티팩트) | `labs/01-etl-dag/` | ⬜ |
| 2 | semaphore 동시성 제한 + 💥 실패 주입 → retry · memoization | `labs/02-concurrency/` | ⬜ |
| 3 | Postgres archive + 컨트롤러 메트릭 Prometheus 수집 | `labs/03-archive-metrics/` | ⬜ |
| 4 | Argo Events Webhook → Workflow 트리거 | `labs/04-events/` | ⬜ |

## 🔥 운영 포인트
- 노드 수만 개 Workflow → etcd 1.5MB 한도 → offloading
- 컨트롤러 workers · QPS/burst, Pod 대량 생성 시 API 서버 압박
- 스팟 노드 재시도 설계, 장시간 작업의 멱등성
- **minor 버전에도 breaking change** → 업그레이드 가이드 필독 (현재 4.1 / 3.7 지원)

## ❓ 자가 점검 질문
1. Argo Workflows, Airflow, Tekton, Temporal은 각각 어떤 상황에 고르는가?
2. 하루 10만 Pod를 만드는 배치 플랫폼을 Argo로 설계한다면 병목은 어디인가?

## 📚 자료
- [Argo Workflows 문서](https://argo-workflows.readthedocs.io/en/latest/) · [Scaling 가이드](https://argo-workflows.readthedocs.io/en/latest/scaling/)
- [4.1 신규 기능](https://argo-workflows.readthedocs.io/en/latest/new-features/) · [지원 정책](https://endoflife.date/argo-workflows)
