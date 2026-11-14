#!/usr/bin/env bash
set -euo pipefail
umask 077
[[ $EUID -eq 0 ]] || { echo 'Run with sudo'; exit 2; }
ACTION="${1:-}"; BASE=/var/local/team6-splunk-guard; SPLUNK=/opt/splunk/bin/splunk
mkdir -p "$BASE"; chmod 700 "$BASE"
collect() {
 local d="$1"; mkdir -p "$d"
 getent passwd | cut -d: -f1,3,4,7 | LC_ALL=C sort > "$d/users"
 getent group | cut -d: -f1,3 | LC_ALL=C sort > "$d/groups"
 # Compare protocol/address/port only; ignore PID and transient process details.
 ss -H -lntu 2>/dev/null | awk '{print $1, $5}' | LC_ALL=C sort -u > "$d/listeners" || true
 systemctl is-active ssh > "$d/ssh-state" 2>/dev/null || true
 if [[ -x "$SPLUNK" ]]; then
   "$SPLUNK" status 2>&1 | sed -E 's/[[:space:]]*pid[=: ]+[0-9]+//Ig' > "$d/splunk-status" || true
   "$SPLUNK" btool check > "$d/splunk-btool" 2>&1 || true
 else echo 'Splunk binary missing' > "$d/splunk-status"; : > "$d/splunk-btool"; fi
 { sha256sum /etc/ssh/sshd_config 2>/dev/null || true; find /etc/ssh/sshd_config.d -maxdepth 1 -type f -exec sha256sum '{}' + 2>/dev/null || true; } | LC_ALL=C sort > "$d/ssh-hashes"
 { for p in /etc/passwd /etc/shadow /etc/group /etc/sudoers; do [[ ! -f "$p" ]] || sha256sum "$p"; done; find /etc/sudoers.d /etc/cron.d /etc/systemd/system -maxdepth 1 -type f -exec sha256sum '{}' + 2>/dev/null || true; } | LC_ALL=C sort > "$d/security-hashes"
 { find /etc/cron.hourly /etc/cron.daily /var/spool/cron/crontabs -maxdepth 2 -type f -printf '%p\n' 2>/dev/null || true; systemctl list-unit-files --no-pager --no-legend --type=service 2>/dev/null || true; } | LC_ALL=C sort > "$d/persistence"
}
case "$ACTION" in
 baseline)
  [[ ! -e "$BASE/baseline" ]] || { echo 'Baseline already exists; not overwriting. Use reset-baseline after reviewing alerts.'; exit 2; }
  tmp=$(mktemp -d "$BASE/.capture.XXXXXXXX"); trap 'rm -rf "$tmp"' EXIT
  collect "$tmp"; mv "$tmp" "$BASE/baseline"; trap - EXIT
  echo "Baseline created at $BASE/baseline" ;;
 reset-baseline)
  [[ -d "$BASE/baseline" ]] || { echo 'No baseline'; exit 2; }
  [[ "${2:-}" == CONFIRMED ]] || { echo 'Usage: sudo bash splunk-guard.sh reset-baseline CONFIRMED'; exit 2; }
  tmp=$(mktemp -d "$BASE/.capture.XXXXXXXX"); trap 'rm -rf "$tmp"' EXIT
  collect "$tmp"; mv "$BASE/baseline" "$BASE/baseline.previous.$(date +%Y%m%d%H%M%S)"; mv "$tmp" "$BASE/baseline"; trap - EXIT
  echo 'New baseline captured; old baseline retained privately.' ;;
 check)
  [[ -d "$BASE/baseline" ]] || { echo 'Run baseline first'; exit 2; }
  tmp=$(mktemp -d "$BASE/.check.XXXXXXXX"); trap 'rm -rf "$tmp"' EXIT; collect "$tmp"
  changed=0
  for f in users groups listeners ssh-state splunk-status splunk-btool ssh-hashes security-hashes persistence; do
    if ! diff -q "$BASE/baseline/$f" "$tmp/$f" >/dev/null; then echo "ALERT: $f changed (review $BASE/baseline/$f against current system)"; changed=1; fi
  done
  if timeout 3 bash -c 'echo > /dev/tcp/127.0.0.1/8089' 2>/dev/null; then echo 'Splunk 8089 TCP reachable (authentication NOT tested)'; else echo 'ALERT: Splunk 8089 TCP not reachable'; changed=1; fi
  exit "$changed" ;;
 *) echo 'Usage: sudo bash splunk-guard.sh baseline|check|reset-baseline CONFIRMED'; exit 2 ;;
esac
