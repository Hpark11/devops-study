# 🗂️ Plan Sources — 지금까지 계획한 모든 내용의 위치

> Claude Code: 계획을 다시 세울 때 이 목록의 **로컬 파일을 전부 읽고** 종합한다.

## A. 로컬 파일 (Claude Code가 직접 읽을 수 있음)

| # | 위치 | 내용 |
|:-:|---|---|
| 1 | `CLAUDE.md` | 튜터 역할, 환경, 교수법 규칙, 언어 규칙, 금지 사항 |
| 2 | `README.md` | 전체 인덱스: 16주 로드맵, 관문 3개, 주차별 진행표, 매주 루틴, 기존 실습 폴더 매핑 |
| 3 | `00-guide/master-plan.md` | 계획서(Claude Doc) 핵심 요약: 목표·원칙·로드맵·관문·주별 시간 배분 |
| 4 | `00-guide/study-method.md` | 학습 원칙 5개, 노트·실습 작성 규칙, 환경 |
| 5 | `00-guide/versions-2026-11.md` | 9개 기술 버전 현황과 최근 변화(출처 링크) |
| 6 | `00-guide/day00-environment-setup.md` | Lima VM + 도구 설치 가이드 (완료됨) |
| 7 | `00-guide/progress-log.md` | **진행 기록: 현재 위치, VM 상태, 배운 것, 대기 중인 예측 질문** |
| 8 | `00-guide/templates/*.md` | 주간 노트, 실습 리포트, 포스트모템, ADR 템플릿 |
| 9 | `01-cni/README.md` + `01-cni/lessons/day01~10` | CNI 2주 상세 계획 (일차별 가이드 10개) |
| 10 | `02-coredns/README.md` ~ `10-capstone/README.md` | 주제별 목표·핵심 개념·실습·운영 포인트·점검 질문·자료 |
| 11 | 기존 실습 폴더 4개 | `prometheus-docker-compose-main/`, `loki-prometheus-grafana-docker-logging-monitoring-tutorial/`, `distributed-tracing-alloy-grafana-tempo-main/`, `OpenTelemetry/` (수정 금지, 05~10에서 재활용) |

## B. 클라우드 (로컬에 반영 완료, 참고용)

| # | 위치 | 내용 | 로컬 반영 |
|:-:|---|---|---|
| 12 | Claude Docs 계획서 https://claude.ai/artifact/JvZvDAc4m6X46RYWtSXuEe | 원본 상세 계획서 (개요·버전표·16주 로드맵 다이어그램·주제별 섹션·캡스톤·참고자료) | 주제별 내용 → 각 `NN-topic/README.md`, 요약 → `master-plan.md`. 사용자가 문서를 1회 직접 수정함(내용 미확인) — Claude Docs 커넥터가 있으면 읽어서 차이를 확인 |
| 13 | claude.ai 채팅 (프로젝트 "Devops Study") | 계획 수립, Day 0 환경 구축, Day 1 Step 1–2 튜터링 기록 | 핵심은 `progress-log.md`에 정리됨 |
