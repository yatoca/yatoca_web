#!/usr/bin/env bash
set -euo pipefail

ZONE_ID="${ZONE_ID:-Z0628504M3ENTXTEYAYA}"

aws route53 change-resource-record-sets \
  --hosted-zone-id "$ZONE_ID" \
  --change-batch file://infrastructure/dns-current-records.json

echo
printf '%s\n' "Route 53 has been pre-staged only. Registrar nameservers were NOT changed."
printf '%s\n' "Current production DNS remains authoritative until you explicitly change delegation at the registrar."
