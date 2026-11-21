# Day 8 — Service LB 벤치마크 (iptables vs eBPF)

> ⏱️ 2~3시간 · 🎯 "eBPF가 빠르다"를 숫자로 확인한다

## 🛠️ 실습
1. 클러스터 2개 준비: (A) kube-proxy iptables, (B) Cilium kube-proxy replacement
2. `labs/08-lb-benchmark/create-services.sh`로 Service 1천 → 5천 → 1만 개 생성
3. 측정 항목

| 항목 | 측정 방법 | A: iptables | B: eBPF |
|---|---|---|---|
| 규칙/엔트리 수 | `iptables-save \| wc -l` / `cilium-dbg bpf lb list \| wc -l` |  |  |
| 규칙 동기화 시간 | kube-proxy `sync_proxy_rules_duration_seconds` |  |  |
| 요청 지연 p50/p99 | `fortio load -qps 1000 -t 60s` |  |  |
| 노드 CPU | `top`, node-exporter |  |  |

4. 결과를 `labs/08-lb-benchmark/RESULT.md`에 기록하고 그래프 1장

## ✅ 확인 질문
- [ ] 차이가 생기는 근본 원인(선형 탐색 vs 해시 조회, 전체 재작성 vs 증분 갱신)을 설명하라
