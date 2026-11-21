# 🔎 02. CoreDNS — 클러스터 DNS

> **기간:** 3주차 (약 10~12시간)
> **핵심:** "간헐적 5초 지연"의 원인을 클라이언트(resolv.conf)와 서버(플러그인 체인) 양쪽에서 설명할 수 있다

---

## 🎯 학습 목표
- [ ] Corefile 구조와 **플러그인 실행 순서**(plugin.cfg 기준)를 설명한다
- [ ] `ndots:5` + search domain이 만드는 쿼리 폭증을 측정하고 줄인다
- [ ] NodeLocal DNSCache 도입 효과를 숫자로 보여 준다
- [ ] CoreDNS 핵심 메트릭으로 장애를 탐지한다

## 🧠 핵심 개념
| 영역 | 내용 |
|---|---|
| 서버 | server block, 플러그인 체인 순서 (CVE-2026-26017: 순서 문제로 ACL 우회) |
| kubernetes 플러그인 | Service / EndpointSlice watch, headless · SRV, `pods insecure\|verified` |
| 주요 플러그인 | `cache`(serve_stale, prefetch) · `forward` · `loop` · `autopath` · `rewrite` · `prometheus` |
| 클라이언트 | `ndots:5`, search domain, glibc vs musl(Alpine), A/AAAA 병렬 질의와 conntrack race |
| 구조 | NodeLocal DNSCache, Cilium DNS proxy와 FQDN 정책 |
| 보안 전송 | DoT / DoH / DoQ, TSIG (1.14대 강화) |

## 🛠️ 실습
| # | 실습 | 위치 | 완료 |
|:-:|---|---|:-:|
| 1 | dnsperf로 `ndots:5` vs FQDN(끝에 `.`) 쿼리 수·지연 비교 | `labs/01-ndots/` | ⬜ |
| 2 | NodeLocal DNSCache 도입 전후 p99 비교 | `labs/02-nodelocal/` | ⬜ |
| 3 | 💥 forward 대상 장애 → `serve_stale` 동작 확인 | `labs/03-serve-stale/` | ⬜ |
| 4 | Go로 커스텀 플러그인 작성 후 빌드 | `labs/04-custom-plugin/` | ⬜ |

## 🔥 운영 포인트
- 스케일링: cluster-proportional-autoscaler, 메모리는 Service 수에 비례
- 메트릭: `coredns_dns_request_duration_seconds`, `coredns_forward_*`, SERVFAIL/NXDOMAIN 비율, cache hit ratio
- upstream 한도: AWS VPC resolver의 ENI당 PPS 제한 등

## ❓ 자가 점검 질문
1. `curl api.example.com` 한 번에 Pod에서 DNS 쿼리가 몇 개 나가는가? 줄이는 방법 3가지는?
2. CoreDNS Pod가 모두 살아 있는데 간헐적으로 타임아웃이 난다. 어떤 순서로 조사하는가?

## 📚 자료
- [CoreDNS 매뉴얼](https://coredns.io/manual/toc/) · [CoreDNS 1.14.5 릴리스](https://coredns.io/2026/07/10/coredns-1.14.5-release/)
- [Kubernetes DNS 디버깅](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/)
