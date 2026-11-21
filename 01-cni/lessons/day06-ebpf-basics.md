# Day 6 — eBPF 기초 (XDP · tc · cgroup · map)

> ⏱️ 2시간 · 🎯 Cilium이 iptables 대신 무엇을 커널에 붙이는지 이해할 기초를 만든다

## 💡 개념 요약

| 개념 | 설명 |
|---|---|
| eBPF 프로그램 | 커널 이벤트에 붙는 샌드박스 코드. verifier가 안전성 검증 후 JIT |
| **XDP** | NIC 드라이버 직후, sk_buff 생성 전. 가장 빠른 drop/redirect |
| **tc (cls_bpf)** | ingress/egress 트래픽 제어 지점. Cilium 데이터패스의 주 무대 |
| **cgroup / socket hook** | `connect()` 시점에 Service IP를 Pod IP로 바꿈 (socket LB) |
| **BPF map** | 커널↔유저 공유 저장소 (hash, LRU, array, ringbuf). 정책·서비스·conntrack 테이블 |
| CO-RE / BTF | 커널 버전 간 이식성 |

```
NIC ─▶ [XDP] ─▶ sk_buff ─▶ [tc ingress] ─▶ 네트워크 스택 ─▶ socket ◀─ [cgroup connect hook]
                                         ◀─ [tc egress] ◀─
```

## 🛠️ 실습
1. 📕 *Learning eBPF* 1~5장 읽기
2. `bpftrace` 원라이너로 감 잡기
   ```bash
   sudo bpftrace -e 'tracepoint:syscalls:sys_enter_connect { @[comm] = count(); }'
   ```
3. 간단한 XDP 프로그램(특정 포트 drop)을 `ip link set dev <if> xdp obj prog.o`로 로드
4. `bpftool prog list`, `bpftool map list`, `bpftool map dump id <id>`

## ✅ 확인 질문
- [ ] XDP와 tc에서 각각 할 수 있는 일, 할 수 없는 일은?
- [ ] eBPF 프로그램이 커널을 망가뜨리지 못하게 하는 장치는?
