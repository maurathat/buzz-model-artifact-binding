# Buzz Phase 2A — Representation Gate 1

**DRAFT — not committed, outside Git. Read-only comparison gate.**
No tag name chosen, no NIP proposed, nothing implemented, nothing opened
upstream. This document establishes the design space only. It deliberately
contains **no recommended representation**.

## 1. Frozen-contract basis

Scored against the semantic contract committed at
`buzz-model-artifact-binding` HEAD `1996b4a0a38f268f4c0f92bbece396561d98ec5f`,
file sha256 `dc4f93a956a71148ca7236e1721560482ef74f1542182e7500199b5f6d7fced3`,
verified from the committed blob. Governing distinction, unweakened:

```text
DECLARED  ≠  EFFECTIVE  ≠  EXECUTED
```

Upstream specs read at nips master `a2494f4` (2026-09-09) and blossom master
`b5bd280`. Buzz-specific behaviour read at the pinned commit
`4cd82f513214aad11c2b742ce7cc7c681e8e32a0`.

Candidates: **A** NIP-94-style `x`/`ox` · **B** NIP-92 `imeta` ·
**C** BUD-09 typed `x` · **D** new semantic tag on an existing structural shape
(control) · **E** `a`/`e` event reference plus type.

## 2. Comparison table

| Candidate | S1 signed | S2 content digest | S3 typed relationship | S4 declared-safe | S5 execution-safe | S6 local verify | S7 location-free | S8 unaware behaviour | S9 existing event | S10 direct/transitive | S11 referent typing | S12 cardinality-neutral |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **A** `x`/`ox` | **PASS** tags are in the id preimage and signature-covered (01.md:32-42) | **PASS** for `x` = sha256 of file bytes (94.md:17). **FAIL** for `ox`, defined only relative to upload-server transformation (94.md:18) | **FAIL** `x` carries no relationship; defined only inside kind 1063 (94.md:13), reuse asserted externally by NIP-92 (92.md:13) | **PASS** nothing in `x` implies effective | **PASS** nothing implies execution | **PASS** hash over supplied bytes | **PASS** the `x` tag alone names no location | **ACTIVE INCORRECT (ecosystem)** — 8 claimants, 2 incompatible: NIP-35 `x` is a BitTorrent v1 infohash (35.md:14,46), NIP-5A `x` is a synthesized aggregate over a manifest (5A.md:36,51); NIP-17 `x` is the hash of the *encrypted* file (17.md:160,174). **SILENT IGNORE (Buzz)** — bare `x` is consumed only inside `imeta` | **PASS** see §4 | **PARTIAL** names bytes either way, but nothing distinguishes manifest from weight object, and NIP-5A already claims `["x",h,"aggregate"]` for the manifest case | **PARTIAL** forces no type; offers no way to express one without colliding (§3) | **PASS** repeatable; NIP-68 uses several `x` tags (68.md:66) |
| **B** `imeta` | **PASS** same basis | **PARTIAL** `x` is optional inside imeta (92.md:13) | **FAIL** types *this metadata describes that URL in my content* — attachment, not provenance (92.md:12) | **PASS** | **PASS** | **PARTIAL** only if `x` present | **FAIL** `url` is a normative MUST (92.md:12); Buzz additionally requires it to be a **local `/media/` path** (imeta.rs:62) | **ACTIVE INCORRECT, CONFIRMED ON FOUR REAL CONSUMERS, INCLUDING UNPROMPTED NETWORK FETCH** — see §3; the decisive one is `timelineImagePreload.ts:19-24,49-54`, which warms `entry.image`/`entry.thumb` with `new Image(); image.src = url` with no user action. Upstream: clients MAY replace imeta URLs with rich previews (92.md:9) | **FAIL** the **relay itself** enforces imeta: a key allowlist rejects any new key (`disallowed imeta key`, imeta.rs:11-14,53), `url`+`m`+`x`+`size` are all mandatory (imeta.rs:162), and `verify_imeta_blobs` requires the blob in tenant media storage (ingest.rs:2996-2999) | **FAIL** media-variant framing | **FAIL** the key allowlist forbids adding a referent-type key | **PASS** repeatable |
| **C** BUD-09 typed `x` | **PASS** same basis | **PASS** sha256 over exact bytes (BUD-02) | **PARTIAL** position 3 *is* a relationship vocabulary, but BUD-09 does not define it — it delegates to NIP-56's report-type enumeration (09.md:19-20 → 56.md:25,29-36), scoped to kind 1984 (09.md:17) | **PASS** | **PASS** | **PASS** | **PASS** BUD-09 carries no URL | **ACTIVE INCORRECT (position 3 collision)** — the third slot is doubly claimed with disjoint vocabularies: NIP-56 requires a report type, NIP-5A requires the literal `"aggregate"`. A Scope A value there is read as one of those by any consumer of either | **PASS** as a shape | **PARTIAL** as A, plus the NIP-5A manifest collision is direct | **PARTIAL** a type slot exists but is already owned | **PASS** |
| **D** new tag, existing shape (control) | **PASS** by construction | **PASS** by construction | **PASS** by construction — this is the only candidate that can define the predicate without contradicting an existing owner | **PASS** by construction | **PASS** by construction | **PASS** by construction | **PASS** by construction | **SILENT IGNORE (Buzz, with one exception), UNDETERMINED (ecosystem)** — ~40 independent positive-name `tag[0] === …` checks, **no exhaustive tag enum, no `switch (tag[0])`, no runtime tag validator** anywhere in the client trees; tags stay `Vec<Vec<String>>` / `string[][]` across the Rust→UI boundary (models.rs:88,208,277,299,399; types.ts:187-197). **Exception:** on a kind-40003 *edit* overlay only `imeta`/`p`/`buzz:mention-snapshot` are carried over, so an unknown tag on an edit is dropped (applyEditTagOverlay.mjs:65-67). But **NIP-01 says nothing normative about unrecognised tags** (01.md:57-90), so ecosystem-wide silent ignore is empirical, not guaranteed | **PARTIAL** supported on the traced original-message path; unknown tags are dropped by the kind-40003 client edit overlay (applyEditTagOverlay.mjs:65-67); push/search/mesh-sync/admin-export paths UNDETERMINED (§4) | **PASS** leaves both open | **PASS** leaves open | **PASS** leaves open |
| **E** `a`/`e` reference + type | **PARTIAL** the tag is signed, but the load-bearing digest lives in a *separate* event signed by a possibly different author — the relationship spans two events | **FAIL** `e` is an event id and `a` a `kind:pubkey:d-tag` coordinate; neither is an artifact content digest | **PARTIAL** a marker/type position exists | **PASS** | **PASS** | **FAIL** requires retrieving the referenced event — a lookup, not a byte-local check | **PARTIAL** no URL, but resolution is required in practice | **UNDETERMINED** depends on the referenced kind | **FAIL** the natural target is kind 1063, which is **not** on the relay's ingest allowlist (`required_scope_for_kind`, ingest.rs:437 with closed default at :546) — established by F-44200 | **PARTIAL** | **PARTIAL** | **PASS** |

## 3. Semantic-collision analysis

**`x` — eight claimants, two mutually incompatible.** NIP-94:17 (sha256 of a
file), NIP-17:160,174 (sha256 of the **encrypted** file), NIP-68:66 (image
hashes), NIP-96:169 (hash after server transformation), NIP-35:14,46
(**BitTorrent v1 infohash** — a different algorithm over a bencoded info dict),
NIP-56:38,86 (hash of a reported blob, position 3 = report type), NIP-5A:36,51
(**synthesized aggregate over a manifest**, position 3 = `"aggregate"`),
NIP-92:29 (NIP-94's `x` inside `imeta`, space-delimited rather than positional).
A consumer reading any `x` as "sha256 of a retrievable file" misreads NIP-35 and
NIP-5A. Within the compatible cluster the *referent* still differs — plaintext
versus ciphertext versus post-transformation copy.

**Does BUD-09's third element change `x`'s meaning?** Per the normative text,
no. BUD-09 says only that the event carries `x` tags with "hashes of the blobs
being reported" (09.md:11) and writes the third element as
`<type-based-on-nip-56>` (09.md:19-20). It neither redefines `x` nor treats
position 3 as free metadata — it selects from a vocabulary **owned by NIP-56**
(56.md:25 requires a report type there; enumeration at :29-36). Within BUD-09
alone the third element is UNDETERMINED; it is determined only by reference.
Critically, **position 3 has a second owner**: NIP-5A mandates the literal
`"aggregate"` there. Same shape, disjoint vocabularies — so the typed-`x` slot
is not free real estate.

**`ox`.** Not useful to Phase 2A. Its definition is relational in the wrong
direction: the original *before transformations done by the upload server*
(94.md:18), which NIP-17:175 further redefines as before **encryption**. Using
it would assert a transformation history the contract says nothing about, and
would misstate the predicate.

**`imeta`.** Reuse invites active interpretation across **four** consumer
populations that actually exist, not one:

| Consumer | What it does with an imeta tag | Cite |
|---|---|---|
| Buzz desktop | parses keyed by `url` (`parseImeta.ts:12-63`), then the markdown `img` renderer dispatches to a video player or `ProgressiveImage`, which sets `<img src>` — a network fetch | markdown.tsx:1475-1497; ProgressiveImage.tsx:110,133 |
| Buzz desktop, **unprompted** | for entries whose `m` starts `video/`, pre-warms `entry.image`/`entry.thumb` via `new Image(); image.src = url` **with no user action** | timelineImagePreload.ts:19-24,49-54 |
| Buzz desktop | drives audio attachments, an agent-snapshot card with a fetched `thumb`, a download `FileCard`, and row-height reservation | markdown.tsx:1246,1257,1284-1291; AgentSnapshotCard.tsx:143,150; rowHeightEstimate.ts:127 |
| admin-web, and the Flutter mobile client | both parse imeta into attachments and render image/video/audio | admin-web/src/App.tsx:619-650,743; mobile/lib/.../message_media.dart:50-100 |

The unprompted pre-warm is the sharpest form of the failure: a declared model
artifact would be **fetched over the network** because a known tag name was
reused. Upstream separately permits rich-preview substitution (92.md:9).
Separately — and independent of any client — the **relay rejects** imeta that is not
Buzz media: a closed key allowlist (imeta.rs:11-14), mandatory `url`+`m`+`x`+
`size` (imeta.rs:162), a local `/media/` path requirement (imeta.rs:62), and a
storage-existence check (ingest.rs:2996-2999). The normative URL MUST alone
makes it structurally incompatible with a location-free identity assertion,
before unaware-verifier behaviour is even considered.

**A new semantic tag.** NIP-01's tag section (01.md:57-90) is **silent** on
tags a client does not recognise — it states neither "ignore" nor "preserve",
and does not distinguish *ignored because unknown* from *preserved but
uninterpreted*. Reporting that plainly rather than inferring: the frequently
assumed "unknown tags are ignored" is **not** a normative guarantee. What *is*
established is narrower and empirical: within Buzz, the relay preserves an
unknown tag's values through the traced path (as data, not as original bytes),
and the client leaves it preserved but uninterpreted on
an original message event — but drops it on an edit overlay (§4). Every tag is
inside the id preimage and signature-covered (01.md:32-42), so anything that
**re-emits the event as a signed Nostr event** cannot drop a tag without breaking
verification. That protection does **not** reach display-layer projections,
which are never re-signed — the edit overlay is exactly such a projection.

## 4. Buzz carrier check — S9, four legs

Question: if an already-allowlisted agent-authored event carries an otherwise
unknown tag, does Buzz preserve it without reinterpreting it?

Agent-authored user-visible content is `KIND_STREAM_MESSAGE` (9) and
`KIND_STREAM_MESSAGE_V2` (`crates/buzz-core/src/kind.rs`), both on the ingest
allowlist (`required_scope_for_kind`, ingest.rs:473 → `Scope::MessagesWrite`).

| Leg | Finding | Cite |
|---|---|---|
| **Ingest validation** | **No tag-name allowlist for kind 9.** Kind-specific validators iterate tags with `match parts[0].as_str()` and a `_ => {}` catch-all, ignoring names they do not know (pattern at ingest.rs:1296-1326). Two validators do fire for kind 9, and both are name-scoped: `validate_link_preview_tags` `continue`s on any tag that is not `link-preview` (ingest.rs, `parts.first() != Some("link-preview")`), and the imeta block runs **only if** imeta tags are present (ingest.rs:2987-2999) | ingest.rs:473, 1296-1326, 2982-2999 |
| **Storage** | Tag values and ordering preserved as data. The whole tags array is converted once and bound into a `JSONB` column (JSONB stores the parsed value, not the original JSON text): `serde_json::to_value(&event.tags)` → `INSERT INTO events (…, tags, …)`. Schema: `tags JSONB NOT NULL` | event.rs:394, 405, 415; migrations/0001_initial_schema.sql:196 |
| **Delivery to a subscriber** | Data round-trip. `row_to_stored_event` reads the `tags` JSONB value and places it, without per-tag change, into the reconstructed event JSON, then deserializes to `nostr::Event` — the delivered event is re-serialized from that value, not replayed from the original wire bytes. No projection, no per-tag filter. A failed reconstruction warns and drops the event rather than emitting a mutated one | event.rs:708-745, specifically :713, :727, :734 |

**S9 = PARTIAL for an inline tag on an allowlisted agent-authored message
event.** Supported on the traced original-message path over WebSocket REQ:
ingest, storage and delivery established from source, and client consumption
established below as preserved-but-uninterpreted. **Not supported on kind-40003
edit overlays, where the client drops unknown tags**, and UNDETERMINED on the
untraced push, search, mesh-sync and admin-export paths.

The relay preserves the tag values and ordering through the traced ingest →
JSONB storage → REQ-delivery path; no per-tag projection or filtering occurs on
that path. This is semantic/data preservation, **not** a claim of byte-identical
wire serialization. The failure found is entirely client-side.

**Scope limit, stated rather than glossed:** I established the ingest → storage →
REQ-delivery path. I did **not** exhaustively audit every downstream consumer
that could re-serialize an event — push-notification payloads, search indexing,
inter-pod/mesh sync, and admin export paths were not traced. Those legs are
**UNDETERMINED**. Signature coverage (01.md:32-42) bounds the risk only for paths
that re-emit a signed event; it says nothing about projections, as the client leg
below shows. That is an argument, not a trace.

**Client-side consumption — the fourth leg.** Tag reads are ~40 independent
positive-name lookups (`formatTimelineMessages.ts:68-72,121-123,188-193,337`;
channelWindowResponse.ts:28). **No exhaustive tag-name enum, no
`switch (tag[0])`, no `TAG_ALLOWLIST`, and no runtime tag validator exists in
any client tree**; tags remain `Vec<Vec<String>>` from the Rust boundary
(models.rs:88,208,277,299,399, filled by raw copy at messages.rs:950-951) to
`string[][]` in TS (types.ts:187-197), with no `deny_unknown_fields` on the
display path. Message inclusion is gated by **kind**, not tags
(`isTimelineContentEvent`, formatTimelineMessages.ts:52-66). For an unknown tag
on an original message event the client state is therefore **preserved but
uninterpreted**: carried through, not rendered, not errored, not dropped.

**One exception, and it is a real limitation.** The edit overlay carries over
only `imeta`, `p` and `buzz:mention-snapshot` from an edit event
(applyEditTagOverlay.mjs:65-67), so **an unknown tag placed on a kind-40003
edit event is dropped client-side.** Unknown tags on the *original* event
survive with their values intact (`droppedFromOriginal` returns true for every name it does not
special-case, :53-63). This is the one client-side tag-name allowlist found. It
is implementation behaviour at the pin, not a normative rule, and it bounds
where an inline declaration could survive display.

Buzz already carries a namespaced custom tag name in-tree
(`buzz:mention-snapshot`, sendToChannelSemantics.ts:43, and honoured by the edit
overlay above) — an existing in-tree precedent for prefixed custom tag names.
Recorded as a fact, not a proposal.

Agent-authored user-visible kinds, precisely: `KIND_STREAM_MESSAGE = 9`
(kind.rs:479), `KIND_STREAM_MESSAGE_V2 = 40002` (:481),
`KIND_STREAM_MESSAGE_EDIT = 40003` (:483), `KIND_STREAM_MESSAGE_DIFF = 40008`
(:493), `KIND_SYSTEM_MESSAGE = 40099` (:497). The agent SDK's `build_message`
emits kind 9 (builders.rs:260).

## 5. Disposition per candidate

| Candidate | Disposition | Basis |
|---|---|---|
| **A** `x`/`ox` | **STRUCTURAL PRECEDENT ONLY** | The digest-carrying shape is useful and byte-local, but `x` fails S3 (no relationship) and carries eight claimants with two incompatible readings. `ox` is separately INCOMPATIBLE — it asserts a transformation history (94.md:18). |
| **B** `imeta` | **INCOMPATIBLE** | Kill condition 3 (location required as part of identity: 92.md:12 MUST, plus a local `/media/` path at imeta.rs:62) and kill condition 4 (active incorrect interpretation, confirmed in Buzz's own renderer). Independently, the relay rejects non-media imeta outright (imeta.rs:11-14,162; ingest.rs:2996-2999). |
| **C** BUD-09 typed `x` | **STRUCTURAL PRECEDENT ONLY** | The digest-plus-type shape is exactly the right shape, and is the closest structural precedent found. But the type slot is already owned twice over with disjoint vocabularies (NIP-56 report types; NIP-5A `"aggregate"`), so occupying it would misstate the contract — kill condition 1 for *semantic* reuse, while the *shape* survives. |
| **D** new tag, existing shape | **VIABLE CONTROL** — qualified | Nothing examined makes it incompatible. It satisfies S1–S7 by construction, is **PARTIAL** on S9 (supported on the traced original-message path, dropped on edit overlays, other paths UNDETERMINED), and leaves S10–S12 open. It is **not** automatically safe. Its S8 standing has three different grades: **normative** — none, NIP-01 is silent on unknown tags; **implementation at the pin** — preserved but uninterpreted on original message events, but **dropped** on kind-40003 edit overlays (applyEditTagOverlay.mjs:65-67); **ecosystem** — UNDETERMINED. "Safe degradation" must therefore be demonstrated per consumer population and per event kind, not assumed from the tag being unknown. |
| **E** `a`/`e` reference + type | **INCOMPATIBLE** | Fails S2 (an event id or coordinate is not an artifact content digest) and S6 (identity check requires retrieving another event). Kill condition 5 also applies — the natural target kind 1063 is not on the relay's allowlist while an inline representation is available. |

Not ranked. No winner chosen. No syntax proposed.

**On kill condition 5:** it is applicable here only because inline carriage is
established on the traced original-message path — the relevant sense of "an
existing-event representation is otherwise possible". S9 is PARTIAL rather than
PASS, so condition 5 is weaker support than it would be under a full PASS; E's
INCOMPATIBLE disposition rests independently on S2 and S6. Had inline carriage
come back wholly UNDETERMINED, condition 5 could not have fired at all.

## 6. Six open semantic-contract questions

| # | Question | Status after this gate |
|---|---|---|
| 1 | Declaration cardinality | **LEFT UNTOUCHED.** Every candidate is repeatable; none forces a cardinality. No candidate's limitation was converted into a semantic answer. |
| 2 | Declared configuration vs transmitted request | **LEFT UNTOUCHED.** Representation-independent; nothing here bears on it. |
| 3 | Digest-algorithm agility | **NARROWED, not resolved.** Every digest-carrying construct examined hardcodes SHA-256 hex (94.md:17; Buzz `imeta x` must be 64-char lowercase hex, imeta.rs:88; BUD-02 sha256). So agility would have to be provided explicitly rather than inherited. Whether it is *required* is still open. |
| 4 | Referent typing | **NARROWED, not resolved.** The existing third-position type slot is doubly owned (§3), so expressing a referent type by reusing it collides. That constrains *how* typing could be expressed; it does not decide *whether* manifest-vs-weight-object typing is required. |
| 5 | Scope-declaration mechanics | **LEFT UNTOUCHED.** |
| 6 | Encoding | **NARROWED, not resolved** — narrowing it is this gate's purpose. Two families are INCOMPATIBLE, two are structural precedent only, one control survives. No encoding chosen. |

**One additional question discovered by this gate** — not one of the six above,
not added to the frozen contract, and not answered here:

| # | Question | Status |
|---|---|---|
| G1-1 | **Edit semantics** | **OPEN FOR DESIGN.** If an original event declares artifact X and a later edit changes the displayed message content, it is unresolved whether the original declaration remains semantically associated with the edited content, whether the edit must carry or redeclare its own relationship, or whether the declaration applies only to the immutable original event. Surfaced by the kind-40003 edit-overlay finding (§4), but it is a semantic question, not a retention one: making the tag survive the overlay would not answer it. |

## 7. Contradictions and UNDETERMINED findings

**Three corrections to the completed census, all against my own earlier claims:**

1. **"A bare `x` may invite Blossom resolution against the author's kind-10063
   server list" is NOT supported.** Blob resolution triggers on a *failed URL*
   (BUD-03:69-74) or a `blossom:` URI (BUD-10:41,111-120) — never on an
   unsolicited `x` tag. NONE FOUND for the claimed behaviour. My earlier S8
   reasoning for `x` overstated the risk by this route; the real risk is the
   eight-claimant ambiguity, which is worse and differently shaped.
2. **BUD-09's third element is narrower than the census implied.** The census
   said it "types what the hash reference means". More precisely: BUD-09 does
   not define it at all and delegates to NIP-56's enumeration. The slot is
   borrowed, not offered.
3. **The census under-reported `x` collisions**, treating NIP-94 and BUD-09 as
   the claimants. There are eight, and NIP-35 and NIP-5A are incompatible with
   the file-hash reading.

**New findings not in the census:** Buzz's relay actively validates and
storage-verifies `imeta` (imeta.rs; ingest.rs:2996-2999) — reuse fails at the
*relay*, not merely at a client; four Buzz consumers interpret imeta, one of
them with an **unprompted network fetch** (timelineImagePreload.ts:19-24,49-54);
and the control candidate D is **qualified** by a client-side carry-over
allowlist on edit overlays (applyEditTagOverlay.mjs:65-67).

**Correction to my own draft of this gate, recorded because it changed a
cell:** before the client inspection returned, I had written that no client-side
tag-name allowlist existed and cited `imetaMediaMarkdown.ts` as the imeta parser.
The fuller inspection found the edit-overlay allowlist above and the primary
parser at `parseImeta.ts:12-63`. Candidate D's S8 cell and disposition were
revised accordingly; the earlier, cleaner reading of D is not what the source
supports.

**Nothing found requires revising the frozen semantic contract.** One note for
the record, short of a revision: the contract's §8 unaware-verifier requirement
is correctly framed as a constraint on later syntax, and this gate confirms it
cannot be discharged by appeal to NIP-01 — since NIP-01 is silent on unknown
tags, §8 can only ever be *demonstrated against a named consumer population*,
never assumed from the standard. That is a strengthening of how §8 must be
tested, not a change to what it requires.

**UNDETERMINED, carried forward:**

1. Ecosystem-wide unaware-consumer behaviour for an unknown tag — NIP-01 is
   silent.
2. Buzz's push-notification, search-indexing, mesh/pod-sync and admin-export
   re-serialization legs — not traced.
3. Whether the upstream `nostr` crate's `Event` deserializer tolerates arbitrary
   tag names in every case — that code is outside the pinned Buzz source. Buzz's
   own handling copies tags as raw strings (`as_slice().to_vec()`), and any tag
   that passed ingest was already parsed by the same library, but the library
   itself was not read.
4. Candidate E's unaware behaviour, which depends on a referent kind not chosen
   here.
