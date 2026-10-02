#!/usr/bin/env bash
set -euo pipefail

mkdir -p /mnt/output

if [[ "$#" -eq 0 || "$1" == -* ]]; then
  exec /bin/bash "$@"
fi

exec "$@"
