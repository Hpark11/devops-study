#!/usr/bin/env bash
# Symptom matrix: pings from every pod to every target, in parallel.
# Shows WHAT is broken, never WHY. Finding the why is your job.
#   sudo ./probe.sh
set -u
cd "$(dirname "$0")" && source ./lib.sh
need_root

targets=(127.0.0.1 self "$GW" 10.88.0.11 10.88.0.12 10.88.0.13 8.8.8.8)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

for ns in "${NS_LIST[@]}"; do
  if ! ip netns list | grep -qw "$ns"; then
    echo "$ns: netns missing" >&2; continue
  fi
  for t in "${targets[@]}"; do
    dst=$t; [[ $t == self ]] && dst=${NS_IP[$ns]}
    ( classify_ping "$ns" "$dst" > "$tmp/$ns-$t" ) &
  done
done
wait

printf '%-5s' "from"
for t in "${targets[@]}"; do printf ' %-13s' "$t"; done; echo
for ns in "${NS_LIST[@]}"; do
  printf '%-5s' "$ns"
  for t in "${targets[@]}"; do
    r=$(cat "$tmp/$ns-$t" 2>/dev/null || echo "-")
    printf ' %-13s' "$r"
  done
  echo
done
