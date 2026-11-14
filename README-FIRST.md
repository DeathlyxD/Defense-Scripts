# Team 6 NETLAB Defense — password and conservative hardening upgrade

No API, Ansible, or dedicated controller. No default passwords or new secrets stored.

**Flag-drop order**
1. VyOS console: follow `vyos/first-run-password.txt`.
2. Palo Alto GUI: follow `paloalto/first-run-password.txt`.
3. Debian Splunk VM: run `sudo bash splunk/first-run-harden.sh`. This changes the **existing** sysadmin password interactively and optionally applies conservative SSH hardening after a second-login confirmation and syntax validation. It never disables password authentication.
4. Change **Splunk application's own admin password separately** through its supported UI if applicable; changing Debian sysadmin does not change Splunk accounts. Confirm Splunk management TCP 8089 and query functionality.
5. Check the packet's Quotient PCR for scored user credentials.
6. Print `credentials/PRINT-AND-FILL-OFFLINE.txt` and write new passwords by hand; **never upload a filled copy**.
7. Run the original VyOS and Splunk monitoring scripts; establish baselines only after verifying configurations.

**Packet constraints:** Password changes allowed, usernames unchanged; preserve ICMP, required services, IPs, routes, NAT, and authorized staff access. Do not scan other teams. Scripts were syntax checked off-device but have **not** been tested on live NETLAB VMs.

**Public GitHub:** Publicly accessible tools satisfy the packet's public-resource requirement, but its aftermath section separately restricts publishing competition details. Do not publish packet screenshots, credentials, configs, evidence, or nonpublic details; a public repository is not automatically exempt.

## Fixed monitor behavior
- Splunk baseline is immutable unless you explicitly run `reset-baseline CONFIRMED` (old baseline retained).
- Listener comparison excludes volatile PID/process output; ephemeral listeners can still generate alerts.
- Splunk now checks privilege-sensitive files, cron entries, and systemd service inventory.
- VyOS checks the saved configuration AND attempts to hash live running config; it explicitly warns when live CLI is unavailable.
- Palo Alto administrator takeover monitoring is a manual CLI/GUI workflow, not continuous automation.
- All checks are alert-only. No firewall changes, auto password resets, automatic rollback, or scanning.
- `sshd -T` prints effective SSH settings for confirmation; this does not guarantee remote login works.
- Actual NETLAB verification still required.
