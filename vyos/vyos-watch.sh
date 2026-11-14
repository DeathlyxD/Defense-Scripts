#!/usr/bin/env bash
# Local VyOS read-only baseline: saved config, live routes, addresses, and running configuration if accessible.
set -euo pipefail; umask 077
ACTION="${1:-}"; BASE="${HOME}/.team6-vyos-monitor"; mkdir -p "$BASE"; chmod 700 "$BASE"
collect() {
 local d="$1"; mkdir -p "$d"
 [[ -r /config/config.boot ]] || { echo 'Saved config unavailable'; return 2; }
 sha256sum /config/config.boot | awk '{print $1}' > "$d/saved-config-hash"
 ip -4 -o address show | LC_ALL=C sort > "$d/addresses"
 ip -4 route show table main | LC_ALL=C sort > "$d/routes"
 # VyOS operational CLI may be available only in an interactive login shell.
 # Capture the live config without printing it to console; if unavailable, report explicitly.
 if command -v /opt/vyatta/bin/vyatta-op-cmd-wrapper >/dev/null 2>&1 && /opt/vyatta/bin/vyatta-op-cmd-wrapper show configuration commands > "$d/running-config" 2>"$d/running-error"; then
   sha256sum "$d/running-config" | awk '{print $1}' > "$d/running-config-hash"
 else echo 'UNAVAILABLE' > "$d/running-config-hash"; fi
 rm -f "$d/running-config" "$d/running-error"
}
case "$ACTION" in
 baseline)
  [[ ! -e "$BASE/baseline" ]] || { echo 'Baseline exists; refusing overwrite'; exit 2; }
  tmp=$(mktemp -d "$BASE/.capture.XXXXXXXX"); trap 'rm -rf "$tmp"' EXIT; collect "$tmp"; mv "$tmp" "$BASE/baseline"; trap - EXIT; echo 'Baseline saved privately.' ;;
 reset-baseline)
  [[ "${2:-}" == CONFIRMED && -d "$BASE/baseline" ]] || { echo 'Usage: bash vyos-watch.sh reset-baseline CONFIRMED'; exit 2; }
  tmp=$(mktemp -d "$BASE/.capture.XXXXXXXX"); trap 'rm -rf "$tmp"' EXIT; collect "$tmp"; mv "$BASE/baseline" "$BASE/baseline.previous.$(date +%Y%m%d%H%M%S)"; mv "$tmp" "$BASE/baseline"; trap - EXIT ;;
 check)
  [[ -d "$BASE/baseline" ]] || { echo 'Run baseline first'; exit 2; }
  tmp=$(mktemp -d "$BASE/.check.XXXXXXXX"); trap 'rm -rf "$tmp"' EXIT; collect "$tmp"; changed=0
  for f in saved-config-hash running-config-hash addresses routes; do
   if ! diff -q "$BASE/baseline/$f" "$tmp/$f" >/dev/null; then echo "ALERT: $f changed"; changed=1; fi
  done
  if grep -qx UNAVAILABLE "$tmp/running-config-hash"; then echo 'WARNING: live running-config inspection unavailable; saved-config-only monitoring is incomplete'; fi
  exit "$changed" ;;
 *) echo 'Usage: bash vyos-watch.sh baseline|check|reset-baseline CONFIRMED'; exit 2 ;;
esac
