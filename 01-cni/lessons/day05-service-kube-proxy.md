# Day 5 — Service · kube-proxy · 💥 MTU 장애 재현

> ⏱️ 2~3시간 · 🎯 ClusterIP 요청이 Pod에 닿기까지의 iptables 체인을 끝까지 따라간다

## 💡 개념 요약

```
KUBE-SERVICES ─▶ KUBE-SVC-XXXX (확률 분배: --probability 0.333…) ─▶ KUBE-SEP-YYYY ─▶ DNAT → PodIP:port
                                                                      └▶ KUBE-MARK-MASQ (필요 시 SNAT)
```

| 모드 | 동작 | 한계 |
|---|---|---|
| iptables | 체인 + 확률 매칭 | 규칙 수 O(N), 갱신 시 전체 재작성 |
| IPVS | 커널 L4 LB, 해시 테이블 | 일부 기능 제한, 유지보수 축소 |
| nftables | set/map 기반, 증분 갱신 | 비교적 최신 (K8s 1.31 beta → GA) |

## 🛠️ 실습
1. Deployment(replicas=3) + ClusterIP Service 생성
2. 노드에서 체인 따라가기
   ```bash
   iptables-save -t nat | grep <service-name>
   iptables -t nat -L KUBE-SVC-XXXX -n -v
   ```
3. NodePort, `externalTrafficPolicy: Local` 각각에서 SNAT 여부와 클라이언트 IP 보존 확인
4. kube-proxy를 nftables 모드로 바꾸고 `nft list ruleset` 비교

## 💥 Break-it: MTU 장애
1. 한 노드의 Pod MTU를 강제로 1500, 경로 MTU는 1400으로 설정
2. 작은 `curl`은 성공, 큰 응답(1MB 파일)은 멈추는 현상 재현
3. `tcpdump`로 ICMP "fragmentation needed" 또는 재전송 패턴 확인
4. 증상 · 원인 · 탐지 방법을 [포스트모템 템플릿](../../00-guide/templates/postmortem.md)으로 정리

## ✅ 확인 질문
- [ ] `externalTrafficPolicy: Local`의 장단점은?
- [ ] Service 엔드포인트가 1만 개일 때 iptables 모드의 문제는?
