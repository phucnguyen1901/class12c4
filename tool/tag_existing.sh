#!/usr/bin/env bash
# One-time: add tag `class12c4` to all images in folder `Images` so they
# appear in the public list-by-tag endpoint.
# Usage:
#   export CLOUDINARY_URL='cloudinary://<key>:<secret>@phucnguyen'
#   bash tool/tag_existing.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -n "${CLOUDINARY_URL:-}" ]] && [[ -z "${CLOUDINARY_API_KEY:-}" ]]; then
  if [[ "$CLOUDINARY_URL" =~ cloudinary://([^:]+):([^@]+)@([^/]+) ]]; then
    CLOUDINARY_API_KEY="${BASH_REMATCH[1]}"
    CLOUDINARY_API_SECRET="${BASH_REMATCH[2]}"
    CLOUDINARY_CLOUD_NAME="${CLOUDINARY_CLOUD_NAME:-${BASH_REMATCH[3]}}"
  fi
fi

: "${CLOUDINARY_API_KEY:?Set CLOUDINARY_API_KEY or CLOUDINARY_URL}"
: "${CLOUDINARY_API_SECRET:?Set CLOUDINARY_API_SECRET or CLOUDINARY_URL}"

CLOUD_NAME="${CLOUDINARY_CLOUD_NAME:-phucnguyen}"
TAG="${CLASS12C4_TAG:-class12c4}"
PREFIX="${CLOUDINARY_PREFIX:-Images}"

LIST_TMP="$(mktemp)"
trap 'rm -f "$LIST_TMP"' EXIT

echo "Fetching image list with prefix '$PREFIX' from cloud '$CLOUD_NAME'..."
curl -fsS -u "$CLOUDINARY_API_KEY:$CLOUDINARY_API_SECRET" \
  "https://api.cloudinary.com/v1_1/${CLOUD_NAME}/resources/image?prefix=${PREFIX}&type=upload&max_results=500" \
  -o "$LIST_TMP"

PUBLIC_IDS_JSON="$(python3 - "$LIST_TMP" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
ids = [r["public_id"] for r in data.get("resources", []) if r.get("public_id")]
print(json.dumps(ids))
PY
)"

COUNT="$(python3 -c "import json; print(len(json.loads('''$PUBLIC_IDS_JSON''')))")"
echo "Found $COUNT image(s). Tagging with '$TAG' in batches of 100..."

python3 - "$PUBLIC_IDS_JSON" "$TAG" "$CLOUD_NAME" "$CLOUDINARY_API_KEY" "$CLOUDINARY_API_SECRET" <<'PY'
import json, sys, urllib.request, urllib.parse, base64

ids = json.loads(sys.argv[1])
tag = sys.argv[2]
cloud = sys.argv[3]
key = sys.argv[4]
secret = sys.argv[5]

url = f"https://api.cloudinary.com/v1_1/{cloud}/resources/image/tags"
auth = base64.b64encode(f"{key}:{secret}".encode()).decode()

batch = 100
for i in range(0, len(ids), batch):
    chunk = ids[i:i+batch]
    params = [("tag", tag), ("command", "add")]
    for pid in chunk:
        params.append(("public_ids[]", pid))
    data = urllib.parse.urlencode(params).encode()
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Authorization", f"Basic {auth}")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    with urllib.request.urlopen(req) as resp:
        body = resp.read().decode()
        tagged = len(json.loads(body).get("public_ids", []))
        print(f"  batch {i//batch + 1}: tagged {tagged} of {len(chunk)}")
print("Done.")
PY
