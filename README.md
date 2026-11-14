# Team 6 — NETLAB native defense edition

**Not live-tested. Read this before execution.** This is a local monitoring and detection toolkit, **not** an automated firewall/router hardener. No Ansible, PAN-OS API, third-party dependencies, controller VM, or credentials embedded. No automatic blocking or rollback. Do not upload captured configurations or evidence.

## Packet-derived environment
- VyOS 1.4.0: external 172.31.26.2/29, gateway 172.31.26.1, PA-side 172.16.0.254/24, Kali-side 172.17.0.1/24.
- PAN-OS 11.0.2: management 172.20.240.200, outside 172.16.0.1/24, inside 172.20.240.254/24.
- Debian 12 / Splunk 10.0.2: internal 172.20.240.20, public mapping 172.25.26.20.

## Flag-drop sequence
1. Change existing passwords manually; never rename users. Check the Quotient PCR process for scored credentials.
2. Verify your current network configuration is legitimate **before** capturing baselines. If the Red Team has already altered it, baselining would trust their changes.
3. On VyOS local Bash shell (not PAN-OS): `bash vyos/vyos-watch.sh baseline`, then `bash vyos/vyos-watch.sh check`. The script checks `/config/config.boot` hash, IPv4 addresses, and routes. It makes **no** configuration changes. Run from a trusted local account. If the configuration path differs, STOP and investigate; do not bypass the check.
4. On Debian Splunk: `sudo bash splunk/splunk-guard.sh baseline`, then `sudo bash splunk/splunk-guard.sh check`. Optional after validation: `sudo bash splunk/install-monitor-timer.sh`. View `/var/log/team6-guard/check.log`. Monitoring records private local data.
5. On Palo Alto: follow `paloalto/cli-checklist.txt` in the native CLI and GUI. There is **no automated continuous Palo Alto config monitoring** in this edition.
6. In Splunk Search, run one search at a time from `splunk/detections/team6-searches.spl`; adjust source types only after confirming log ingestion. Searches are examples inspired by vendor detection practices, not copied upstream content.

## Safety boundaries
- Preserve usernames, hostnames, IP addresses, public NAT mappings, scored services, ICMP, and authorized White/Green/Black access.
- No scanning other teams, staff systems, or global assets; no broad blocking, automated restoration, snapshots, resets, or destructive hardening.
- Do not use private external staging or restricted software. Public GitHub publication of competition-specific details requires organizer clearance; the packet restricts public communication of competition details.
- Scoring: uptime 40%, injects 40%, incident response 20%. Keep reports/evidence private and submit via prescribed process.
- Baselines are *not* automatically trusted. Capture only after confirming current settings. `check` exit status 1 indicates drift, not proof of compromise.

## Important limitations
- `/config/config.boot` reflects saved VyOS config, not necessarily uncommitted candidate configuration. Monitor operational changes with route/address diffs; check live configuration manually as needed.
- Debian listener comparisons can generate noise from ephemeral ports; review alerts before responding. Splunk TCP 8089 reachability is not proof of authenticated functionality.
- Splunk detections require matching indexed logs. Empty results are inconclusive.
- No third-party SDK/Ansible packages are included. No scripts execute on PAN-OS.
- Scripts were syntax-checked off-device, **not** verified on competition VMs. Stop if output differs from expectations.
