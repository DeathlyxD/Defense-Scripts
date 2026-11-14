#!/usr/bin/env bash
# Optional, local Debian monitoring. No network changes, no daemon installs.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo 'Run with sudo'; exit 2; }
SCRIPT="$(cd "$(dirname "$0")" && pwd)/splunk-guard.sh"
[ -f /var/local/team6-splunk-guard/baseline/users ] || { echo 'Run baseline first'; exit 2; }
mkdir -p /var/log/team6-guard
cat > /etc/systemd/system/team6-guard.service <<EOF
[Unit]
Description=Team 6 local Splunk integrity check
[Service]
Type=oneshot
ExecStart=/bin/bash $SCRIPT check
StandardOutput=append:/var/log/team6-guard/check.log
StandardError=append:/var/log/team6-guard/check.log
EOF
cat > /etc/systemd/system/team6-guard.timer <<'EOF'
[Unit]
Description=Run Team 6 integrity check every two minutes
[Timer]
OnBootSec=2min
OnUnitActiveSec=2min
Unit=team6-guard.service
[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now team6-guard.timer
echo 'Timer enabled. View: systemctl status team6-guard.timer; tail -n 80 /var/log/team6-guard/check.log'
