# Day 9 — NetworkPolicy · L7/FQDN 정책 · Hubble

> ⏱️ 2~3시간 · 🎯 정책으로 막고, Hubble로 "왜 막혔는지" 찾는다

## 💡 개념 요약

| 정책 | 레이어 | 특징 |
|---|---|---|
| NetworkPolicy (K8s 표준) | L3/L4 | 선택되지 않은 Pod는 전부 허용, 선택되면 명시한 것만 허용 |
| CiliumNetworkPolicy | L3/L4/**L7** | HTTP 메서드·경로, Kafka 토픽, DNS/FQDN(`toFQDNs`) |
| Cluster Network Policy | 클러스터 범위 | admin 우선 정책 (로드맵) |

Cilium은 정책을 **identity**(레이블 기반 숫자 ID)로 평가한다 → IP가 바뀌어도 정책 유지.

## 🛠️ 실습
1. `frontend → backend`만 허용하는 default-deny 정책 작성
2. Hubble로 관찰
   ```bash
   cilium hubble port-forward &
   hubble observe --verdict DROPPED -f
   hubble observe --to-pod default/backend --protocol http
   ```
3. L7 정책: `GET /api/*`만 허용, `POST`는 차단 → 403 확인
4. FQDN 정책: `api.github.com`만 외부 허용
5. Hubble UI로 서비스 맵 확인

## 💥 Break-it
- 레이블 오타가 있는 정책을 적용 → 증상(timeout)과 Hubble에서 drop reason 찾기
- 기록은 [포스트모템 템플릿](../../00-guide/templates/postmortem.md)으로

## ✅ 확인 질문
- [ ] L7 정책을 걸면 트래픽 경로에 무엇이 추가되는가? (Envoy proxy)
- [ ] FQDN 정책이 DNS 프록시에 의존하는 이유는? → 3주차 CoreDNS와 연결
