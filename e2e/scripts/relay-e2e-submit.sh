#!/usr/bin/env bash
# Phase 2A live Buzz relay E2E on an admitted global event (kind 1).
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
export BUZZ_AUTO_MIGRATE=true; export RUST_LOG="info,buzz_relay::handlers::ingest=debug"
case "$DATABASE_URL" in */"$DB") : ;; *) echo "ABORT: DATABASE_URL not isolated"; exit 1 ;; esac
echo "## 3. ISOLATED RELAY STATE"
echo "relay commit:  $(git -C "$W" rev-parse HEAD)"
echo "relay binary:  $W/target/debug/buzz-relay  (mtime $(stat -f '%Sm' "$W/target/debug/buzz-relay"))"
echo "database:      $DB   (DATABASE_URL masked: postgres://***@localhost/${DB})"
echo "bind address:  $BUZZ_BIND_ADDR    relay URL: $RELAY_URL    health/metrics: 3013/3014"
docker exec buzz-postgres psql -U "$PGUSER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB';" | grep -q 1 \
  || docker exec buzz-postgres psql -U "$PGUSER" -d postgres -c "CREATE DATABASE $DB;" >/dev/null
echo "database created/exists: yes"
"$W/target/debug/buzz-relay" > "$E/relay.log" 2>&1 & RELAY_PID=$!
trap 'kill $RELAY_PID 2>/dev/null' EXIT
for i in $(seq 1 60); do nc -z localhost $PORT 2>/dev/null && break
  kill -0 $RELAY_PID 2>/dev/null || { echo "ABORT: relay exited"; tail -15 "$E/relay.log"; exit 1; }; sleep 1; done
nc -z localhost $PORT 2>/dev/null || { echo "ABORT: relay never listened"; tail -15 "$E/relay.log"; exit 1; }
TBL=$(docker exec buzz-postgres psql -U "$PGUSER" -d "$DB" -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema='public';" | tr -d ' ')
echo "startup/migration: relay listening (pid $RELAY_PID); migrated tables in $DB: $TBL"
./scripts/seed-local-community.sh > "$E/seed.log" 2>&1 && echo "host->community seed: ok ($(docker exec buzz-postgres psql -U "$PGUSER" -d "$DB" -tAc "SELECT count(*) FROM communities;" | tr -d ' ') rows)" || { echo "SEED FAILED"; tail -5 "$E/seed.log"; }
echo "pre-existing buzz database untouched: $(docker exec buzz-postgres psql -U "$PGUSER" -d buzz -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema='public';" | tr -d ' ') tables"

echo; echo "## 4. DETERMINISTIC DEMO ARTIFACT"
printf 'BUZZ model-artifact binding demo\nphase 2A reference artifact\n' > "$E/demo-artifact.bin"
DIGEST=$(shasum -a 256 "$E/demo-artifact.bin" | cut -d' ' -f1)
echo "construction:  printf 'BUZZ model-artifact binding demo\\nphase 2A reference artifact\\n'"
echo "byte count:    $(wc -c < "$E/demo-artifact.bin" | tr -d ' ')"
echo "sha256:        $DIGEST"
python3 -c "
d='$DIGEST'; ok = len(d)==64 and all(c in '0123456789abcdef' for c in d)
print('profile lexical form (64 lowercase hex):', 'VALID' if ok else 'INVALID')"

echo; echo "## 5. REAL SIGNED EVENT (fixture identity, kind 1)"
SEC=$(cat "$KEY")
nak event --sec "$SEC" -k 1 -c "Model artifact declaration (Phase 2A demo)" \
  -t "declared-model-artifact=$DIGEST" </dev/null 2>/dev/null > "$E/event-submitted.json"
unset SEC
python3 - "$E/event-submitted.json" <<'PY'
import json,sys
e=json.load(open(sys.argv[1]))
print("event id:    ", e["id"]); print("pubkey:      ", e["pubkey"]); print("created_at:  ", e["created_at"])
print("kind:        ", e["kind"]); print("tags:        ", json.dumps(e["tags"])); print("content:     ", json.dumps(e["content"]))
print("sig:         ", e["sig"])
PY
echo "-- pre-submit verification with the committed verifier --"
python3 "$MAB/verifier/mab_verify.py" --event "$E/event-submitted.json" --candidate "$E/demo-artifact.bin"

echo; echo "## 6. SUBMIT THROUGH THE REAL RELAY (NIP-42 AUTH)"
BEFORE=$(wc -l < "$E/relay.log")
SEC=$(cat "$KEY")
REPLY=$(cat "$E/event-submitted.json" | nak event --auth --sec "$SEC" "$RELAY_URL" 2>&1 | tail -4)
unset SEC
echo "relay reply: $REPLY"
echo "relay log (new lines, filtered):"
tail -n +$((BEFORE+1)) "$E/relay.log" | grep -iE "auth|ingest|accept|reject|restrict|stored|invalid" | tail -8 | sed 's/^/  /'
EID=$(python3 -c "import json;print(json.load(open('$E/event-submitted.json'))['id'])")
echo "-- persistence proof: query the isolated database by exact event id --"
docker exec buzz-postgres psql -U "$PGUSER" -d "$DB" -tAc "SELECT column_name,data_type FROM information_schema.columns WHERE table_name='events' AND column_name='id';" | sed 's/^/  events.id type: /'
docker exec buzz-postgres psql -U "$PGUSER" -d "$DB" -tAc "SELECT count(*) FROM events WHERE encode(id,'hex')='$EID';" 2>/dev/null | sed 's/^/  rows matching event id (bytea): /'
docker exec buzz-postgres psql -U "$PGUSER" -d "$DB" -tAc "SELECT count(*) FROM events WHERE id='$EID';" 2>/dev/null | sed 's/^/  rows matching event id (text):  /'
docker exec buzz-postgres psql -U "$PGUSER" -d "$DB" -tAc "SELECT kind, count(*) FROM events GROUP BY kind ORDER BY kind;" | sed 's/^/  stored by kind: /'

echo; echo "## 7. RETRIEVE THROUGH HISTORICAL REQ"
nak req -i "$EID" "$RELAY_URL" </dev/null 2>/dev/null | head -1 > "$E/event-retrieved.json"
echo "retrieved bytes: $(wc -c < "$E/event-retrieved.json" | tr -d ' ')"
python3 - "$E/event-submitted.json" "$E/event-retrieved.json" "$DIGEST" <<'PY'
import json,sys
a=json.load(open(sys.argv[1])); b=json.load(open(sys.argv[2])); dig=sys.argv[3]
print("submitted vs retrieved semantic fields:")
for f in ("id","pubkey","created_at","kind","tags","content","sig"):
    same = a[f]==b[f]
    print(f"  {f:<11} {'identical' if same else 'DIFFERS'}")
t=[x for x in b["tags"] if x and x[0]=="declared-model-artifact"]
print(f"  relationship tags found: {len(t)}")
if t:
    tag=t[0]
    print(f"  exactly two elements: {len(tag)==2}")
    print(f"  carrier exact:        {tag[0]=='declared-model-artifact'}")
    print(f"  digest equals submitted: {tag[1]==dig}")
PY

echo; echo "## 8. INDEPENDENT VERIFICATION OF THE RETRIEVED EVENT"
python3 "$MAB/verifier/mab_verify.py" --event "$E/event-retrieved.json" --candidate "$E/demo-artifact.bin"
echo "-- human presentation --"
python3 "$MAB/verifier/mab_verify.py" --event "$E/event-retrieved.json" --candidate "$E/demo-artifact.bin" --human

echo; echo "## 9. ONE-BYTE ADVERSARIAL CHECK"
python3 -c "
b=open('$E/demo-artifact.bin','rb').read(); m=b[:-1]+bytes([b[-1]^1])
open('$E/demo-artifact-mutated.bin','wb').write(m)
print('mutated last byte', b[-1], '->', m[-1], '| same length:', len(b)==len(m))"
python3 "$MAB/verifier/mab_verify.py" --event "$E/event-retrieved.json" --candidate "$E/demo-artifact-mutated.bin"
python3 "$MAB/verifier/mab_verify.py" --event "$E/event-retrieved.json" --candidate "$E/demo-artifact-mutated.bin" --human | head -4
kill $RELAY_PID 2>/dev/null; echo; echo "relay stopped"
