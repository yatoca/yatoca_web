#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${DOMAIN:-yatoca.pe}"
WWW_DOMAIN="${WWW_DOMAIN:-www.yatoca.pe}"

printf '\n== Website ==\n'
for path in / /home/ /gallery/ /directory/ /talk/ /about-us/; do
  code="$(curl -sS -o /dev/null -w '%{http_code}' "https://${DOMAIN}${path}")"
  printf '%-20s %s\n' "$path" "$code"
done

printf '\n== WWW ==\n'
curl -sS -o /dev/null -w '%{url_effective} -> HTTP %{http_code}\n' "https://${WWW_DOMAIN}/"

printf '\n== API ==\n'
curl -sS "https://${DOMAIN}/api/opiniones-hero"
printf '\n'

printf '\n== Nameservers ==\n'
dig @1.1.1.1 "$DOMAIN" NS +short | sort

printf '\n== MX ==\n'
dig @1.1.1.1 "$DOMAIN" MX +short | sort -n

printf '\n== Apex TXT ==\n'
dig @1.1.1.1 "$DOMAIN" TXT +short | sort

printf '\n== DMARC ==\n'
dig @1.1.1.1 "_dmarc.${DOMAIN}" TXT +short

printf '\n== DKIM ==\n'
for name in k2 k3 s1 s2; do
  printf '%s: ' "$name"
  dig @1.1.1.1 "${name}._domainkey.${DOMAIN}" CNAME +short
 done

printf '\n== TLS SAN ==\n'
echo | openssl s_client -servername "$DOMAIN" -connect "${DOMAIN}:443" 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates -ext subjectAltName
