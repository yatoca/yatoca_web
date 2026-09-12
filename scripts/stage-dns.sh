#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'MSG'
ERROR: scripts/stage-dns.sh is deprecated and intentionally disabled.

Route 53 became authoritative and the Yatoca website was cut over to CloudFront
on 2026-09-12. The old staging change set pointed the website to DigitalOcean
and must not be reapplied.

See:
  docs/AWS_PRODUCTION_ARCHITECTURE.md
  infrastructure/dns-production-reference.json
  infrastructure/terraform/
MSG
exit 1
