# Phase 2A — Buzz Relay End-to-End Carrier Proof

**Buzz relay end-to-end carrier proof on an admitted global event.** A real
signed Nostr event carrying the frozen `declared-model-artifact` relationship
traversed a live Buzz relay and the event retrieved from the relay — not the
pre-submit object — passed the committed reference verifier against the declared
artifact bytes.

## Identity

| | |
|---|---|
| Phase 2A commit | `a58fe4d02c9f72f918cdda93127177462e748c84` |
| Buzz commit | `4cd82f513214aad11c2b742ce7cc7c681e8e32a0` |
| normative profile | `4de926b95fb4eb3791b861a671c652b7270d83e491502ec21145a9d62c5117c0` |
| reference-test specification | `dd752441750a6e6f6f76000504b3dfe7a9d7218480438d911f57d38c4ff99868` |
| vector corpus | `cb3d45dd0a16c253ca07ef77061241b737275f3787a12df052042ad44be2535c` |
| verifier SHA-256 | `4ee8e5cfd8aad4eebe9f229767cf460b4b4d4898a0f165aca1e99b5d8dba4356` |
| fixture public key | `e54731bf9eb26d40b4cba1249c9f482de3c3d63e2c44ec29ae636ad71718cedd` |
| isolated database | `buzz_phase2a_e2e` |
| relay URL | `ws://localhost:3002` (bind `127.0.0.1:3002`, health 3013, metrics 3014) |

The fixture private key is not recorded here, is not in this repository, and
lives outside it at mode 0600. It was read only by the signing command.

## Artifact

| | |
|---|---|
| file | `demo-artifact.bin` |
| byte count | 61 |
| SHA-256 | `eff10530b153a17f0f91d44a59f95f20abece1eb3f6dfe237327085b8cbac13d` |

The digest is SHA-256 **over the literal artifact bytes**. No canonicalization,
JCS, NFC, decompression, framing or prefixing participates.

## Event

| field | value |
|---|---|
| id | `891746dac88d1bdcac66835216e1e45d4dcbb3674735f95fb547245d61b78352` |
| pubkey | `e54731bf9eb26d40b4cba1249c9f482de3c3d63e2c44ec29ae636ad71718cedd` |
| created_at | 1791698333 |
| kind | 1 |
| tags | `[["declared-model-artifact", "eff10530b153a17f0f91d44a59f95f20abece1eb3f6dfe237327085b8cbac13d"]]` |
| content | `"Model artifact declaration (Phase 2A demo)"` |
| sig | `5a696c8483acf93ec3536e1c92e28ab0ca51bc2794e247cf6a29725f190fd16ad6af9a0c64bb4d3c8bac1600a339cc9a1b5021281b3fbd4ce6c7c3ff8d775197` |

Exactly one relationship tag of exactly two elements. No algorithm field, model
name, referent type, URL or location, version, or execution/effective-model
data.

**Kind 1 was selected because it is an already-admitted global path requiring no
fabricated channel membership.** Source basis at the Buzz commit above:
`ingest.rs:440` maps `KIND_TEXT_NOTE | KIND_LONG_FORM` to
`Scope::MessagesWrite`; `ingest.rs:624` `is_global_only_kind` includes
`KIND_TEXT_NOTE`, so kind 1 is never channel-scoped.

**Kind 9 stream-message carriage is UNTESTED in this checkpoint** because its
channel/membership prerequisites were not provisionable through the supported
local tooling identified. `ingest.rs:707` `requires_h_channel_scope` includes
`KIND_STREAM_MESSAGE`, and `ingest.rs:745` `check_channel_membership` then
requires membership or an open channel; `scripts/seed-local-community.sh`
inserts only `communities (host)` rows — no users, members, agents or channels.
**No channel or membership records were fabricated.** Nothing observed suggests
the relationship tag would cause a problem on that path.

## Relay proof

1. **NIP-42 authentication succeeded** for the fixture identity
   `e54731bf…1718cedd`. No registration, membership or ownership record was
   created; authentication alone admitted the key for this kind.
2. **Ingest accepted the event** — `Event ingested via pipeline` and
   `Event ingested`, both carrying event id `891746dac88d1bdcac668352…`, kind 1.
3. **Persistence was proven by exact event-id query, not inferred from an OK
   response:**

   ```sql
   -- events.id is bytea
   SELECT count(*) FROM events WHERE encode(id,'hex')='891746dac88d1bdcac66835216e1e45d4dcbb3674735f95fb547245d61b78352';  -- 1
   SELECT kind, count(*) FROM events GROUP BY kind;                    -- 1|1
   ```

4. **Historical authenticated REQ returned exactly the event** —
   `EOSE sent after historical delivery, count=1`.
5. **Submitted and retrieved semantic fields matched** for `id`, `pubkey`,
   `created_at`, `kind`, `tags`, `content` and `sig` — all seven identical.
6. **`declared-model-artifact` remained exactly a two-element tag** with the
   exact submitted digest `eff10530b153a17f0f91d44a59f95f20abece1eb3f6dfe237327085b8cbac13d`.

This is a claim about **semantic tag values and order**. It does **not** claim
that the original JSON wire bytes were preserved; that was not tested.

## Retrieved-event verification

Machine result from the committed verifier against the retrieved event and the
artifact bytes:

```json
{
  "established": {
    "author_signed_valid_declaration": true,
    "candidate_is_not_declared_artifact": false,
    "candidate_matches_declared_digest": true
  },
  "relationship_instance_valid": true,
  "signature_valid": true
}
```

Human presentation:

```
event signature                   PASS
declaration                       VALID
artifact digest                   MATCH

author signed declaration         ESTABLISHED
declared model artifact           ESTABLISHED
effective model                   NOT ESTABLISHED
execution                         NOT ESTABLISHED
```

## Mutation test

The mutation is deterministic: the last byte of `demo-artifact.bin` is XORed
with 1, leaving the length unchanged. `relay-e2e-retrieve-verify.sh` derives it
from the preserved artifact, so the mutated file is not committed.

| | |
|---|---|
| original SHA-256 | `eff10530b153a17f0f91d44a59f95f20abece1eb3f6dfe237327085b8cbac13d` |
| mutated SHA-256 | `7883589b188b26b5a25ba57542fccdde9b4fb36372038d12b15dc481a22de0c0` |
| bytes differing | 1 |

Against the **same retrieved event**, unmodified:

```json
{
  "established": {
    "author_signed_valid_declaration": true,
    "candidate_is_not_declared_artifact": true,
    "candidate_matches_declared_digest": false
  },
  "relationship_instance_valid": true,
  "signature_valid": true
}
```

The mutation does not invalidate the signed declaration. It demonstrates that
the mutated candidate bytes are not the artifact identified by that declaration.

## Relay-log extraction

The raw relay logs are not committed. `scripts/relay-log-filter.sh` is the
complete extraction rule and reproduces `relay-evidence.log` byte for byte from
the raw logs.

| | |
|---|---|
| extraction command | `relay-log-filter.sh <raw-submit.log> <raw-retrieve.log>` |
| rule | select lines whose `message` is one of `NIP-42 auth successful`, `Event ingested via pipeline`, `Event ingested`, `EOSE sent after historical delivery` |
| raw submit log SHA-256 | `72be33fe0919fa283e946bcdf48a73d9ff176f19bcdc2b8c1d85676331518891` |
| raw retrieve log SHA-256 | `726094a56f1a928dd22745e47931a11c8f70f9d47b4d095dc6e341730e496478` |
| committed extract SHA-256 | `ff21ba2d4fe19b94f3eb4434c963039915656c2b0b6cebd207e56b70170940d2` |

No line in the extract is hand-selected or edited. The raw logs are retained
outside the repository.

## Operational finding: the REQ tooling trap

Authenticated historical retrieval requires the appropriate `nak req`
authentication mode; an unauthenticated REQ returns nothing.

Separately, **`nak` writes progress to stderr and the event to stdout.** Merging
the streams before selecting the event yields the progress line
`connecting to localhost:3002... ok.` instead of the event, which looks exactly
like an empty result even when the relay has delivered correctly — the relay log
showed `count=1` while the merged capture appeared empty. The reproduction
script keeps the streams separate for this reason.

This is tooling behaviour, not a relay semantic claim.

## Scope of the demonstrated claim

This checkpoint demonstrates carriage of the frozen `declared-model-artifact`
relationship through an admitted Buzz global-event path:

```
signed event
  → NIP-42 authentication
  → ingest
  → persistence
  → historical REQ retrieval
  → independent artifact verification
```

It does **not** establish kind-9 or channel-scoped integration, effective model
selection, model loading, serving, inference participation, execution, or
execution attestation.

```
DECLARED ≠ EFFECTIVE ≠ EXECUTED
```

## Reproduction

`scripts/relay-e2e-submit.sh` runs the full procedure including a fresh
submission; because `created_at` is the wall clock, it produces a *new* event
with a different id and signature. It reproduces the procedure, not this
recorded event. `scripts/relay-e2e-retrieve-verify.sh` reproduces the recorded
result exactly: it retrieves **this** event id from the isolated database
through authenticated REQ, verifies it, and runs the mutation test.

Buzz source was not modified. The pre-existing `buzz` database was never
written.
