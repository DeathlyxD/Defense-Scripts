#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run with sudo'; exit 1; }
[[ -f /etc/debian_version ]] || { echo 'Not Debian. Stopping.'; exit 1; }
id sysadmin >/dev/null || { echo 'sysadmin missing. Stopping.'; exit 1; }
echo 'Change the existing sysadmin password now; write it down offline.'
passwd sysadmin
echo 'Verify a SECOND login with the new password before continuing.'
read -r -p 'Second login successful? Type YES: ' ok
[[ "$ok" == YES ]] || exit 0
[[ -x /usr/sbin/sshd ]] || { echo 'No sshd found; stopping.'; exit 0; }
if grep -REiq '^[[:space:]]*(Match|MaxAuthTries|LoginGraceTime|PermitRootLogin)[[:space:]]' /etc/ssh/sshd_config /etc/ssh/sshd_config.d 2>/dev/null; then
  echo 'Existing SSH overrides found; skip SSH changes for safety.'; exit 0
fi
mkdir -p /root/team6-backup /etc/ssh/sshd_config.d
chmod 700 /root/team6-backup
cp -a /etc/ssh/sshd_config "/root/team6-backup/sshd_config.$(date +%s)"
cat >/etc/ssh/sshd_config.d/05-team6-guard.conf <<'CFG'
PermitRootLogin no
MaxAuthTries 4
LoginGraceTime 45
CFG
if ! /usr/sbin/sshd -t; then
  rm -f /etc/ssh/sshd_config.d/05-team6-guard.conf
  echo 'SSH validation failed; changes removed.'; exit 1
fi
if ! systemctl reload ssh; then
  rm -f /etc/ssh/sshd_config.d/05-team6-guard.conf
  echo 'Reload failed; changes removed.'; exit 1
fi
echo 'SSH guard applied. Check effective settings: sshd -T | grep -E "^(permitrootlogin|maxauthtries|logingracetime) "'; echo 'Verify fresh sysadmin login and scored services.'
