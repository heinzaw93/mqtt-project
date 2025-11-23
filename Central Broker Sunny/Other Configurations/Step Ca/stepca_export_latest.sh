#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d)"
/usr/bin/rsync -a --delete /home/step/.step/db/ "$TMP/"

# Export JSON, keep only VALID (not revoked/expired), pick latest per CN,
# and include both hex and decimal serials.
OUT="$(/usr/local/bin/step-badger x509Certs "$TMP" --emit=json --serial --time=short \
| /usr/bin/jq -c '
    # keep only valid certs (defense-in-depth even if flags change)
    map(select((.Revoked|not) and (.Validity? == null or .Validity == "Valid")))
    | sort_by(.Certificate.Subject.CommonName, .Certificate.NotBefore)
    | group_by(.Certificate.Subject.CommonName)
    | map(max_by(.Certificate.NotBefore))
    | map({
        cn:         .Certificate.Subject.CommonName,
        serial_hex: .StringSerials.SerialHex,
        serial_dec: (.StringSerials.SerialDecimal // .StringSerials.SerialDec // .SerialNumber),
        issued:     .Certificate.NotBefore,
        expire:     .Certificate.NotAfter
      })
')"

rm -rf "$TMP"

# Always emit valid JSON ([] if empty)
if [ -z "$OUT" ]; then
  echo "[]"
else
  echo "$OUT"
fi
