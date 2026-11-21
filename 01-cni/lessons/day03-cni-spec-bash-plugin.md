# Day 3 ⭐ — CNI 스펙 + bash로 CNI 플러그인 직접 구현

> ⏱️ 3시간 · 🎯 kubelet이 CNI 바이너리를 어떻게 호출하는지 알고, 동작하는 최소 플러그인을 만든다

## 💡 개념 요약

```
kubelet ──CRI──▶ containerd ──(netns 생성)──▶ CNI plugin 실행
                                    │  env: CNI_COMMAND=ADD, CNI_NETNS, CNI_IFNAME, CNI_CONTAINERID
                                    │  stdin: /etc/cni/net.d/*.conflist (JSON)
                                    ▼
                              stdout: 결과 JSON (IP, routes, interfaces)
```

| 항목 | 내용 |
|---|---|
| 명령 | `ADD` · `DEL` · `CHECK` · `VERSION` (+ 1.1의 `GC`, `STATUS`) |
| 위치 | 설정 `/etc/cni/net.d/`, 바이너리 `/opt/cni/bin/` |
| 체인 | conflist의 `plugins[]` 순서대로 실행 (예: main → portmap → bandwidth) |
| 플러그인 종류 | **main**(bridge, ptp, macvlan) · **ipam**(host-local, dhcp) · **meta**(portmap, tuning, bandwidth) |

## 🛠️ 실습
1. kind 클러스터를 CNI 없이 생성
   ```yaml
   # labs/03-bash-cni/kind.yaml
   kind: Cluster
   apiVersion: kind.x-k8s.io/v1alpha4
   networking:
     disableDefaultCNI: true
   nodes: [{role: control-plane}, {role: worker}]
   ```
2. 노드가 `NotReady`인 이유 확인 (`kubectl describe node`)
3. `labs/03-bash-cni/my-cni` 작성 — Day 1의 명령을 `CNI_COMMAND`별로 정리
   - `ADD`: veth 생성 → netns로 이동 → IP 할당(노드 podCIDR에서 파일 기반 카운터) → 라우트 → 결과 JSON 출력
   - `DEL`: veth 삭제, IP 반납
   - `VERSION`: 지원 버전 JSON
4. 각 노드의 `/opt/cni/bin/`, `/etc/cni/net.d/10-my-cni.conf`에 복사 (`docker cp`)
5. 노드 간 통신용 라우트 추가: 노드 A에 `ip route add <B podCIDR> via <B nodeIP>`
6. nginx Deployment 2개 띄우고 노드 간 Pod 통신 확인
7. 레퍼런스와 비교: [bridge 플러그인 소스](https://github.com/containernetworking/plugins/tree/main/plugins/main/bridge)

## 💥 Break-it
- `ADD`에서 잘못된 JSON 출력 → kubelet 이벤트에 어떤 에러가 찍히는지 확인
- IP 카운터 파일을 지워 IP 중복 할당 재현

## ✅ 확인 질문
- [ ] Pod 삭제 시 `DEL`이 호출되지 않으면 무엇이 누수되는가?
- [ ] Cilium/Calico 같은 실제 CNI는 이 bash 스크립트 대비 무엇을 추가로 하는가? (데몬, CRD, 정책, IPAM 서버…)
