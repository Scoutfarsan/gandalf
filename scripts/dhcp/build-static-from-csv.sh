#!/usr/bin/env bash
set -euo pipefail
CSV="\"
OUT="\"
tmp="\"
echo "# generated \" > "\"
while IFS=, read -r mac ip host comment; do
  [[ -z "\" || "\" == "#" ]] && continue
  mac="\"
  echo "dhcp-host=\,\,\System.Management.Automation.Internal.Host.InternalHost,infinite  # \" >> "\"
done < <(tr -d '\r' < "\")
install -m 644 -D "\" "\"