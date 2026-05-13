#!/usr/bin/env bash
# Regenerate assets/manifest.json from Cloudinary Admin API.
# Usage:
#   export CLOUDINARY_API_KEY=...
#   export CLOUDINARY_API_SECRET=...
#   export CLOUDINARY_CLOUD_NAME=phucnguyen   # optional
#   export CLOUDINARY_PREFIX=Images           # optional (folder prefix)
#   bash tool/fetch_manifest.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/assets/manifest.json"

if [[ -n "${CLOUDINARY_URL:-}" ]] && [[ -z "${CLOUDINARY_API_KEY:-}" ]]; then
  # cloudinary://API_KEY:API_SECRET@cloud_name
  if [[ "$CLOUDINARY_URL" =~ cloudinary://([^:]+):([^@]+)@([^/]+) ]]; then
    CLOUDINARY_API_KEY="${BASH_REMATCH[1]}"
    CLOUDINARY_API_SECRET="${BASH_REMATCH[2]}"
    CLOUDINARY_CLOUD_NAME="${CLOUDINARY_CLOUD_NAME:-${BASH_REMATCH[3]}}"
  fi
fi

: "${CLOUDINARY_API_KEY:?Set CLOUDINARY_API_KEY or CLOUDINARY_URL}"
: "${CLOUDINARY_API_SECRET:?Set CLOUDINARY_API_SECRET or CLOUDINARY_URL}"

CLOUD_NAME="${CLOUDINARY_CLOUD_NAME:-phucnguyen}"
PREFIX="${CLOUDINARY_PREFIX:-Images}"

mkdir -p "$(dirname "$OUT")"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

curl -fsS -u "$CLOUDINARY_API_KEY:$CLOUDINARY_API_SECRET" \
  "https://api.cloudinary.com/v1_1/${CLOUD_NAME}/resources/image?prefix=${PREFIX}&type=upload&max_results=500" \
  -o "$TMP"

python3 - "$TMP" "$OUT" <<'PY'
import json, sys
src, dst = sys.argv[1], sys.argv[2]
with open(src, encoding="utf-8") as f:
    data = json.load(f)
items = []
for r in data.get("resources", []):
    pid = r.get("public_id")
    if not pid:
        continue
    items.append({
        "public_id": pid,
        "w": r.get("width"),
        "h": r.get("height"),
    })
items.sort(key=lambda x: x["public_id"])
with open(dst, "w", encoding="utf-8") as f:
    json.dump(items, f, ensure_ascii=False, indent=2)
    f.write("\n")
print(f"Wrote {len(items)} entries to {dst}")
PY
