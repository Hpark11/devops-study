# 📦 버전 현황 (2026-11-19 기준)

> 각 주차를 시작하기 전에 최신 릴리스 노트를 30분 읽고 이 표를 갱신한다.

| 기술 | 기준 버전 | 꼭 알아야 할 최근 변화 | 링크 |
|---|---|---|---|
| **Istio** | 1.30 / 1.31 | 1.24 ambient GA → 1.30 agentgateway, ambient multicluster 강화 · 1.31부터 gcr.io 배포 중단 | [1.31](https://istio.io/news/releases/1.31.x/announcing-1.31/) |
| **Argo Workflows** | 4.1 (3.7 지원) | 4.0(2026-02), 4.1(2026-08) · SemVer 아님, minor에도 breaking change | [releases](https://argo-workflows.readthedocs.io/en/latest/releases/) |
| **CoreDNS** | 1.14.x | 플러그인 실행 순서 ACL 우회 CVE-2026-26017 수정, DoH/DoQ·TSIG 강화 | [1.14.3](https://coredns.io/2026/03/06/coredns-1.14.3-release/) |
| **Cilium** | 1.19 / 1.20 | 1.19 암호화 strict mode·ztunnel beta · 1.20 Gateway API 확장·datapath plugin | [1.20](https://isovalent.com/blog/post/cilium-1-20/) |
| **Prometheus** | 3.x (3.13 LTS) | Native histogram stable, OTLP 수신, UTF-8, Remote Write 2.0 | [3.0](https://prometheus.io/blog/2024/11/14/prometheus-3-0/) |
| **Loki** | 3.7 | Helm 차트 grafana-community 이관 · **Promtail 2026-03-02 EOL → Alloy** | [3.7](https://grafana.com/docs/loki/latest/release-notes/v3-7/) |
| **Grafana** | 13.x | Dynamic dashboards(schema v2) GA, Git Sync GA | [13](https://grafana.com/blog/grafana-13-release-all-the-latest-features) |
| **Datadog** | SaaS | DASH 2026: Bits AI 자율 조사·조치, Bits Code, MCP | [DASH 2026](https://www.datadoghq.com/blog/dash-2026-new-feature-roundup-keynote/) |
| **Sentry** | SaaS / self-hosted 26.x | Seer Agent(2026-04), self-hosted는 Kafka·Snuba·ClickHouse | [Seer Agent](https://sentry.io/about/press-releases/sentry-launches-seer-agent/) |
