# Day 7 — Cilium 설치 · kube-proxy replacement

> ⏱️ 2시간 · 🎯 kube-proxy 없이 Service가 동작하는 것을 확인하고, 무엇이 그 일을 하는지 찾는다

## 🛠️ 실습
1. kind를 CNI 없음 + kube-proxy 없음으로 생성
   ```yaml
   networking:
     disableDefaultCNI: true
     kubeProxyMode: none
   ```
2. Cilium 설치
   ```bash
   cilium install --set kubeProxyReplacement=true --set hubble.enabled=true
   cilium status --wait
   cilium connectivity test
   ```
3. 내부 들여다보기
   ```bash
   kubectl -n kube-system exec ds/cilium -- cilium-dbg service list
   kubectl -n kube-system exec ds/cilium -- cilium-dbg bpf lb list
   kubectl -n kube-system exec ds/cilium -- cilium-dbg bpf ct list global | head
   kubectl -n kube-system exec ds/cilium -- cilium-dbg endpoint list
   iptables-save | wc -l    # kube-proxy 대비 규칙 수 비교
   ```
4. Pod 하나의 veth에 붙은 tc 프로그램 확인: `tc filter show dev <lxc...> ingress`

## 📌 정리 포인트
- Cilium에는 bridge가 없다 → `lxc*` 인터페이스 + tc eBPF로 직접 라우팅
- Service DNAT는 socket LB(connect 시점) 또는 tc에서 처리
- conntrack은 커널 nf_conntrack이 아니라 **BPF CT map**

## ✅ 확인 질문
- [ ] Cilium agent가 죽으면 기존 트래픽은 계속 흐르는가? 새 Pod는?
