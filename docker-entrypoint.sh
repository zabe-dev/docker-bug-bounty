#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f /opt/wordlists/SecLists/Discovery/Web-Content/common.txt ]]; then
  git clone --depth 1 --filter=blob:none --sparse \
    https://github.com/danielmiessler/SecLists.git /opt/wordlists/SecLists
  git -C /opt/wordlists/SecLists sparse-checkout set Discovery Fuzzing Passwords Usernames
  chown -R bug-bounty:bug-bounty /opt/wordlists
fi

mkdir -p /mnt/output
chown bug-bounty:bug-bounty /mnt/output

if [[ "$#" -eq 0 || "$1" == -* ]]; then
  exec runuser -u bug-bounty -- /bin/bash "$@"
fi

exec runuser -u bug-bounty -- "$@"
