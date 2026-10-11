#!/usr/bin/env bash
# Model-Artifact Binding — one-command demo.
#
#   ./demo/run-demo.sh            replay the preserved proof (no infrastructure)
#   ./demo/run-demo.sh --live     run the full round trip through a local Buzz relay
#
# Replay mode uses the committed evidence in e2e/ and needs nothing but Python 3.
# Live mode additionally needs the Buzz checkout, Docker Postgres, and the
# fixture signing key; it is the same procedure, run live.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
MODE="${1:-replay}"

rule() { printf '%s\n' "────────────────────────────────────────────────────────────"; }
step() { printf '\n▸ %s\n' "$1"; }
sha256() { if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1
           else sha256sum "$1" | cut -d' ' -f1; fi; }
# Runs the verifier and aborts loudly if it fails. A demo that silently prints
# an empty panel is worse than one that stops and says why.
verify() {
  local out status
  out="$(python3 "$ROOT/verifier/mab_verify.py" "$@" 2>&1)"; status=$?
  if [ $status -ne 0 ]; then
    printf '\n  VERIFIER FAILED (exit %s). Demo stopped.\n%s\n' "$status" "$out"
    exit 1
  fi
  printf '%s\n' "$out"
}

cat <<'BANNER'
╭──────────────────────────────────────────────────────────────╮
│  Model-Artifact Binding — Phase 2A                           │
│  A signed Nostr event declares the SHA-256 of a model        │
│  artifact. Buzz carries it. Anyone can verify the bytes.     │
│  What it never claims: which model actually ran.             │
╰──────────────────────────────────────────────────────────────╯
BANNER

if [ "$MODE" = "--live" ]; then
  step "LIVE: emit → NIP-42 → ingest → persistence → historical REQ"
  echo "  (running the preserved procedure against a local relay)"
  # Derived output stays outside the repository: this script is part of the
  # committed package and must not drop files into it.
  LIVE_OUT="$(mktemp -t mab-live)"
  bash "$ROOT/e2e/scripts/relay-e2e-retrieve-verify.sh" > "$LIVE_OUT" 2>&1 || {
    echo "  live run failed; transcript: $LIVE_OUT"; exit 1; }
  EVENT_SRC="$(grep -o 'work dir:[[:space:]]*.*' "$LIVE_OUT" | head -1 | awk '{print $3}')/event-retrieved.json"
  if [ ! -f "$EVENT_SRC" ]; then
    echo "  could not locate the retrieved event from the live run."
    echo "  expected it at: $EVENT_SRC"
    echo "  full transcript: $LIVE_OUT"
    exit 1
  fi
  grep -E 'identical|found:|carrier exactly|digest equals|EOSE|relay:' "$LIVE_OUT" | sed 's/^/  /' | head -12
  echo "  full transcript: $LIVE_OUT"
else
  step "REPLAY: the event Buzz returned, as preserved in this repository"
  EVENT_SRC="$ROOT/e2e/event-retrieved.json"
  [ -f "$EVENT_SRC" ] || { echo "  missing evidence: $EVENT_SRC"; exit 1; }
  echo "  evidence: e2e/event-retrieved.json (retrieved from the relay, not the submitted object)"
  echo "  run with --live to perform the relay round trip instead"
fi

ARTIFACT="$ROOT/e2e/demo-artifact.bin"
step "The artifact and the declaration"
printf '  artifact bytes : %s bytes\n' "$(wc -c < "$ARTIFACT" | tr -d ' ')"
printf '  sha256         : %s\n' "$(sha256 "$ARTIFACT")"
python3 - "$EVENT_SRC" <<'PY'
import json,sys
e=json.load(open(sys.argv[1]))
tag=[t for t in e["tags"] if t and t[0]=="declared-model-artifact"][0]
print(f'  event id       : {e["id"]}')
print(f'  author         : {e["pubkey"]}')
print(f'  the whole tag  : {json.dumps(tag)}')
PY

step "Independent verification of the retrieved event"
rule
verify --event "$EVENT_SRC" --candidate "$ARTIFACT" --human
rule

step "Now change one byte of the artifact and verify again"
MUT="$(mktemp)"
python3 - "$ARTIFACT" "$MUT" <<'PY'
import sys
b=open(sys.argv[1],'rb').read(); m=b[:-1]+bytes([b[-1]^1])
open(sys.argv[2],'wb').write(m)
import hashlib
print(f'  one byte flipped, same length')
print(f'  sha256 now     : {hashlib.sha256(m).hexdigest()}')
PY
rule
verify --event "$EVENT_SRC" --candidate "$MUT" --human | sed -n '1,3p'
rule
rm -f "$MUT"

cat <<'CLOSE'

▸ What just happened

  The signature stayed valid and the declaration stayed valid. Only the
  artifact digest changed from MATCH to NO MATCH.

  The author really did sign that declaration — flipping a byte of the
  artifact cannot forge or break that. What changed is whether these
  particular bytes are the artifact the declaration identifies.

  That is the whole point: a declaration records what an author asserted
  about an artifact's identity. It never claims which model was selected,
  loaded, served, or executed.

      DECLARED  ≠  EFFECTIVE  ≠  EXECUTED

▸ Verify the conformance corpus too

  python3 verifier/mab_verify.py --corpus CONFORMANCE-VECTORS.json
CLOSE
