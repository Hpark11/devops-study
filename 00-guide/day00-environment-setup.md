# 🧰 Day 0 — 실습 환경 준비 (macOS → Linux VM)

> ⏱️ 1시간 · 🎯 커널(iptables · eBPF)을 직접 만질 수 있는 Linux VM과 도구 세트를 준비한다

## 왜 VM인가?
macOS의 Docker Desktop은 Linux 커널을 숨겨진 VM 안에 두기 때문에 `ip netns`, `iptables`, `bpftool`을 직접 다룰 수 없다.
→ **Lima**로 Ubuntu VM을 만들고, 그 안에서 Docker + kind를 돌린다.

```
macOS ─▶ Lima VM (Ubuntu 24.04, vz) ─▶ Docker ─▶ kind 노드(컨테이너) ─▶ Pod
          ▲ 여기서 ip/iptables/bpftool 실습
```

## 1) Lima 설치 · VM 생성 (macOS 터미널)
```bash
brew install lima
limactl start --name=devops \
  --cpus=4 --memory=8 --disk=60 \
  --vm-type=vz --mount-writable \
  template://ubuntu-24.04
limactl shell devops          # VM 접속
```
> `--mount-writable`: macOS 홈 디렉토리가 VM에서 쓰기 가능하게 마운트된다 → 이 학습 폴더에 바로 커밋 가능

## 2) 기본 네트워킹 도구 (VM 안)
```bash
sudo apt-get update
sudo apt-get install -y iproute2 iptables nftables conntrack bridge-utils \
  tcpdump iperf3 dnsutils jq curl git make gcc clang llvm \
  linux-tools-common linux-tools-$(uname -r) bpftrace
```

## 3) Docker
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
exit && limactl shell devops   # 그룹 반영을 위해 재접속
docker run --rm hello-world
```

## 4) Kubernetes 도구
```bash
ARCH=$(dpkg --print-architecture)   # Apple Silicon이면 arm64
# kind
curl -Lo kind https://kind.sigs.k8s.io/dl/latest/kind-linux-$ARCH && chmod +x kind && sudo mv kind /usr/local/bin/
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/$ARCH/kubectl" && chmod +x kubectl && sudo mv kubectl /usr/local/bin/
# helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
# cilium / hubble CLI 는 Day 7에 설치
```

## 5) 동작 확인
```bash
uname -r && ip -V && sudo iptables -V && sudo bpftool version
kind create cluster --name smoke && kubectl get nodes && kind delete cluster --name smoke
```

## 6) 학습 폴더 Git 초기화
```bash
cd ~/Documents/hyunsoo/study/DevOps
git init && printf '.DS_Store\n**/tempo-data/\n**/.data/\n**/build/\n**/.gradle/\n*.jar\n' > .gitignore
git add . && git commit -m "chore: study repo init"
```

## ✅ 체크
- [ ] `limactl list`에서 devops VM이 Running
- [ ] VM 안에서 `sudo ip netns add test && sudo ip netns del test` 성공
- [ ] kind 클러스터 생성/삭제 성공
- [ ] Git 첫 커밋 완료

➡️ 다음: [01-cni / Day 1](../01-cni/lessons/day01-netns-veth-bridge.md)
