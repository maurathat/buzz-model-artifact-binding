#!/usr/bin/env bash
set -uo pipefail
W="${BUZZ_SRC:-$HOME/Workspace/buzz}"
# Preserved evidence inputs live one level up; derived outputs go to a work dir
# so a reproduction run never writes into the repository.
EVID="$(cd "$(dirname "$0")/.." && pwd)"
E="${WORK:-$(mktemp -d)}"
for p in event-submitted.json demo-artifact.bin; do [ -f "$EVID/$p" ] && cp "$EVID/$p" "$E/"; done
echo "evidence dir: $EVID"; echo "work dir:     $E"
KEY="${FIXTURE_KEY:-/Users/mauraclark/uor-buzz-relay-private/phase2a/fixture.sec}"
MAB="$(cd "$EVID/.." && pwd)"
PORT=3002; DB=buzz_phase2a_e2e
cd "$W" || exit 1
set -o allexport; source .env; set +o allexport
export DATABASE_URL="postgres://${PGUSER}:${PGPASSWORD}@localhost:${PGPORT:-5432}/${DB}"
export PGDATABASE="$DB"; export BUZZ_BIND_ADDR="127.0.0.1:${PORT}"
export RELAY_URL="ws://localhost:${PORT}"; export BUZZ_HEALTH_PORT=3013; export BUZZ_METRICS_PORT=3014
export BUZZ_AUTO_MIGRATE=true; export RUST_LOG="info,buzz_relay::handlers=debug"
case "$DATABASE_URL" in */"$DB") : ;; *) echo "ABORT"; exit 1 ;; esac
EID=$(python3 -c "import json;print(json.load(open('$E/event-submitted.json'))['id'])")
DIGEST=$(shasum -a 256 "$E/demo-artifact.bin" | cut -d' ' -f1)
"$W/target/debug/buzz-relay" > "$E/relay-final.log" 2>&1 & RP=$!
trap 'kill $RP 2>/dev/null' EXIT
for i in $(seq 1 60); do nc -z localhost $PORT 2>/dev/null && break; sleep 1; done
echo "## 7. RETRIEVE THROUGH HISTORICAL REQ (stdout only)"
SEC=$(cat "$KEY")
nak req --fpa --auth --sec "$SEC" -i "$EID" "$RELAY_URL" </dev/null 2>/dev/null > "$E/event-retrieved.json"
unset SEC
echo "retrieved bytes: $(wc -c < "$E/event-retrieved.json" | tr -d ' ')"
grep -iE 'EOSE sent after historical' "$E/relay-final.log" | tail -1 | python3 -c "
import sys,json
l=sys.stdin.read().strip()
if l: d=json.loads(l); print(f'  relay: {d[\"message\"]}, count={d.get(\"count\")}, sub_id={d.get(\"sub_id\")}')"
python3 - "$E/event-submitted.json" "$E/event-retrieved.json" "$DIGEST" <<'PY'
import json,sys
a=json.load(open(sys.argv[1])); b=json.load(open(sys.argv[2])); dig=sys.argv[3]
print("submitted vs retrieved semantic fields:")
allsame=True
for f in ("id","pubkey","created_at","kind","tags","content","sig"):
    s=a[f]==b[f]; allsame&=s
    print(f"  {f:<11} {'identical' if s else 'DIFFERS'}")
print(f"  all seven identical: {allsame}")
t=[x for x in b["tags"] if x and x[0]=="declared-model-artifact"]
print(f"relationship tag in the RETRIEVED event:")
print(f"  found: {len(t)}  | exactly two elements: {len(t[0])==2 if t else False}")
print(f"  carrier exactly 'declared-model-artifact': {t[0][0]=='declared-model-artifact' if t else False}")
print(f"  digest equals the submitted digest: {t[0][1]==dig if t else False}")
print(f"  retrieved digest: {t[0][1] if t else None}")
PY
echo; echo "## 8. COMMITTED VERIFIER AGAINST THE RETRIEVED EVENT"
python3 "$MAB/verifier/mab_verify.py" --event "$E/event-retrieved.json" --candidate "$E/demo-artifact.bin"
echo "-- human presentation --"
python3 "$MAB/verifier/mab_verify.py" --event "$E/event-retrieved.json" --candidate "$E/demo-artifact.bin" --human
echo; echo "## 9. ONE-BYTE ADVERSARIAL CHECK (retrieved event unmodified)"
python3 -c "
b=open('$E/demo-artifact.bin','rb').read(); m=b[:-1]+bytes([b[-1]^1])
open('$E/demo-artifact-mutated.bin','wb').write(m)
import hashlib
print('  original sha256:', hashlib.sha256(b).hexdigest())
print('  mutated  sha256:', hashlib.sha256(m).hexdigest())
print('  same length:', len(b)==len(m), '| bytes differing:', sum(x!=y for x,y in zip(b,m)))"
python3 "$MAB/verifier/mab_verify.py" --event "$E/event-retrieved.json" --candidate "$E/demo-artifact-mutated.bin"
python3 "$MAB/verifier/mab_verify.py" --event "$E/event-retrieved.json" --candidate "$E/demo-artifact-mutated.bin" --human | head -3
kill $RP 2>/dev/null; echo; echo "relay stopped"
