# 📘 학습 방법

## 원칙

| # | 원칙 | 실천 방법 |
|:-:|---|---|
| 1 | **한 레이어 아래까지 판다** | Istio → Envoy/xDS, CNI → eBPF·iptables, Prometheus → TSDB 블록 |
| 2 | **장애로 배운다** | 주제마다 Break-it 실습 최소 2개 |
| 3 | **비용·카디널리티를 숫자로 말한다** | 관측성 도구는 "series 수 × 보존 기간 × 해상도"로 설명 |
| 4 | **OSS vs SaaS를 같이 본다** | 같은 문제를 Prometheus/Loki와 Datadog/Sentry로 비교 |
| 5 | **매주 산출물을 남긴다** | 다이어그램 1장 + 실습 커밋 + 1페이지 노트 |

## 노트 작성 규칙

- 파일명: `notes/YYYY-MM-DD-주제.md` (예: `notes/2026-11-24-netns-veth.md`)
- 첫 줄에 **한 문장 요약**을 쓴다 → 나중에 훑어볼 때 이것만 읽어도 되게
- "왜?"에 답하지 못한 것은 `❓ 열린 질문` 섹션에 남긴다
- 명령어 출력은 핵심 줄만 붙이고, 해석을 바로 아래에 적는다

## 실습 규칙

- 실습마다 `labs/<번호>-<이름>/` 폴더를 만들고 `README.md`에 재현 절차를 적는다
- 환경 정보(OS, 커널, 버전)를 반드시 기록한다
- 끝나면 [실습 리포트 템플릿](./templates/lab-report.md)으로 결과 정리

## 환경

- **Linux VM 권장**: macOS Docker Desktop에서는 커널 레벨(iptables, eBPF)이 가려진다
  - Lima / Multipass / UTM 또는 클라우드 VM (Ubuntu 24.04, 4 vCPU / 8 GB 이상)
- 공통 도구: `kind`, `kubectl`, `helm`, `k9s`, `jq`, `yq`, `tcpdump`, `bpftool`
