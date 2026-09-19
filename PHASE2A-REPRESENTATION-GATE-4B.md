# Buzz Phase 2A — Representation Gate 4B: Carrier Naming and Indexing

**Status at writing: review draft, prepared outside Git.** Decides the indexing
class first, then selects the public carrier name within it. It changes nothing
else in the representation, implements nothing, builds no vectors, modifies
nothing in Buzz and opens nothing upstream.

## 1. Committed basis

`buzz-model-artifact-binding` HEAD `f4ad75967ae3211df18a681c29b75d0290f78534`:

| File | sha256 (committed blob) |
|---|---|
| `.gitignore` | `cf237c7aff44efbe6e502e645c3e06da03a69d7bdeb43392108ef3348143417e` |
| `PHASE2A-SEMANTIC-CONTRACT.md` | `94fc88e53759d83083ee679c8189f6b54c3d08cc19d6caa1f557945d5ab7cbc5` |
| `PHASE2A-REPRESENTATION-GATE-1.md` | `6177d39cc9b96a59f1184132d3bc7fc4d7cfeb06f696c48868e6544dd5a2568d` |
| `PHASE2A-REPRESENTATION-GATE-2.md` | `0c2b1dce38aa1e70c368eb79e6c9d14dffd3e3a0d003eaf6a54ef9a8853c5dba` |
| `PHASE2A-REPRESENTATION-GATE-3.md` | `bc124fd17a915f8ad0272491692fd42372385253558fb598f4fe89810de330c2` |
| `PHASE2A-REPRESENTATION-GATE-4A.md` | `1c05e8cf102f1fbd35e58ac5120d7e5ab88e47b15e14a5309c077e8cadb7cdbb` |

**Frozen representation (unchanged here):** shape `[<carrier>, <digest>]`; the
signed event supplies the declarant; the carrier definition supplies the Scope A
predicate and fixes SHA-256; the digest is SHA-256 over the complete literal
artifact bytes, written as exactly 64 lowercase hex characters; arity is exactly
2; extra elements are INVALID; nothing is normalized; there is no UOR, JCS or
NFC dependency. Gate 4B chooses only `<carrier>`.

Sources: nips `a2494f4` (2026-09-09); blossom `b5bd280`; Buzz pinned at
`4cd82f513214aad11c2b742ce7cc7c681e8e32a0`, with the `nostr` crate at 0.44.7 per
its `Cargo.lock`.

## 2. NIP-01 indexing semantics

What NIP-01 establishes, read from the text:

* Single-letter tag names (`a-z`, `A-Z`) are "expected to be indexed by relays",
  and "only the first value in any given tag is indexed" (01.md:84). The wording
  is *expected* — a convention, not a MUST.
* The filter key is `"#<single-letter (a-zA-Z)>"` (01.md:130). **Only
  single-letter names are addressable by tag filters at all.** A multi-character
  tag name has no NIP-01 filter key.

So NIP-01 creates an *expectation* of indexing for single letters, and makes
multi-character tags non-queryable by construction. It guarantees neither
indexing nor completeness on any particular relay.

## 3. Pinned Buzz indexing behaviour

| # | Question | Finding | Cite |
|---|---|---|---|
| 1 | Which tag names are indexed (pushed into SQL)? | `h` (channel scope), `p` (single value, via an `event_mentions` join), `d` (only for NIP-33 kinds) and `e` (JSONB containment). Any other generic tag "is not pushed" | `handlers/req.rs:876-901` (`filter_fully_pushable`), `:1007-1045` (`filter_to_query_params`) |
| 2 | Is filtering limited to single-character names? | **Yes, structurally.** Filter `generic_tags` are keyed by the `nostr` crate's `SingleLetterTag` type | `nostr-0.44.7/src/filter.rs:81`; `buzz-core/src/filter.rs:68` |
| 3 | Is the first tag value the one matched? | Yes. In-memory matching compares the filter value against `t.content()`, the first value | `buzz-core/src/filter.rs:68-77` |
| 4 | Does `#<letter>` filtering work for an otherwise unknown letter? | **Live:** yes — newly published events are matched against subscriptions in full (`subscription.rs:551`, `filters_match`). **Historical:** only as a post-filter. One SQL query per filter runs with `LIMIT ≤ 1000` (`DEFAULT_MAX_PAGE_LIMIT`, `buzz-db/src/store/event.rs:33`) *without* the tag constraint, and Rust then discards non-matches (`req.rs:450`). Matching events outside that candidate window are silently missed. The code states the hazard for un-pushed tags itself: other events "push the caller's events past the LIMIT before post-filtering" (`req.rs:1018-1020`). **Historical lookup by an unknown letter is incomplete by construction** | as cited |
| 5 | Is there a fixed indexed-tag allowlist? | Effectively yes: the pushdown set in row 1. Membership is by code path, not configuration | `req.rs:876-901` |
| 6 | Does a 64-character value get special treatment? | None found on the filter path | `buzz-core/src/filter.rs:68-77` |
| 7 | Are multi-character or namespaced tags queryable the same way? | No: they cannot be expressed as filter keys (row 2). Separately, a non-NIP REST path pushes one internal name, `buzz-channel`, by JSONB containment (`api/bridge.rs:1430` → `store/event.rs:615`) | as cited |
| 8 | Does kind 9 differ from other message kinds? | No kind-9-specific tag-filter logic was found on the filter path | `buzz-core/src/filter.rs`, `req.rs` |

A physical index that could serve arbitrary tag containment already exists: a GIN
`jsonb_path_ops` index on the whole `tags` column (`migrations/0004`). The query
builder, though, uses containment only for `e` and `buzz-channel`. **At the pin,
a new single-letter carrier would therefore not become a reliable relay query
dimension.** It would give complete live matching and incomplete historical
matching — accidental, partial semantics — unless Buzz changed its pushdown
rules. This is a finding about the pinned Buzz relay only; it is not generalized
to other Nostr relays. No probe was needed: the source settles Decision A.

## 4. Indexed vs non-indexed decision

**Is relay lookup part of Scope A?** No. Gate 4A established that verification
needs no lookup: signature, digest and candidate bytes are local (contract §3,
§5). Discovery — finding events that declare artifact X — appears nowhere in the
contract, in Gates 1–4A, or in the six open questions.

```text
Relay indexing for Scope A: UNNECESSARY
```

It is not REQUIRED, since verification needs no discovery. It is not CONTRARY
TO SCOPE: nothing in the contract forbids discovery. And it is not "useful but
optional" *for Scope A*: no committed use case needs it.

```text
DECISION A: NON-INDEXED BY DESIGN
```

**What that means, precisely.** The carrier does not intentionally invoke
NIP-01's single-letter tag-indexing convention, and relay indexing is not part of
the Scope A contract. It is **not** a guarantee that no relay, database, client
or downstream service will independently index the tag. The decision is:

```text
relay indexing is not part of the Scope A contract
+
the carrier does not request it through NIP-01's single-letter convention
```

**The concrete reason.** Scope A needs no relay discovery. Choosing the indexed
class would add a public query dimension no requirement asks for, and at the
Buzz pin it would not even deliver reliable indexing — only live matching plus an
incomplete historical post-filter. The same rule used at every gate — don't
promote an optional capability into protocol semantics without a requirement —
selects NON-INDEXED BY DESIGN.

## 5. Privacy, correlation, burden and utility

**Observability — stated as capability, not judged.** The relationship is public
either way: it sits in a signed event any recipient can read. INDEXED would add
*efficient reverse lookup*, letting a relay operator or a subscriber with filter
access ask "which events or agents declare artifact X" without receiving and
scanning everything. NON-INDEXED does **not** hide the data. It leaves reverse
lookup to whoever already holds the events.

**Correlation.** A stable content digest links every declaration of the same
artifact. INDEXED makes that join a relay operation; NON-INDEXED makes it a local
operation over events already received.

**Relay burden.** In Buzz the storage cost of a containment index is already
paid (the GIN index on `tags`). Making a new dimension reliably queryable would
need a code change to the pushdown rules. The broader ecosystem cost is
UNDETERMINED.

**Utility.** Of verification, search/discovery, audit and analytics, only the
first is in the frozen minimum contract, and it needs no index. No committed
Phase 2A use case needs reverse lookup.

**Costs of NON-INDEXED, checked against committed requirements:**
* clients must already hold the event to interpret it — consistent with contract
  §5, where verification starts from an event in hand;
* relay-side reverse lookup is not guaranteed — no requirement asks for it;
* artifact-centric applications must index locally after subscribing — permitted;
* a discovery mechanism could be standardized separately later.

None of these violates a committed requirement.

## 6. Bounded candidate census

Because Decision A is NON-INDEXED BY DESIGN, single-letter names are excluded without
examining letters. By NIP-01 convention a single letter would create exactly the
`#<letter>` semantics Decision A declines (criterion N8). Candidates are
multi-character or namespaced only: three serious candidates plus one control.

Searched for each name: NIPs at `a2494f4` (tag form `["<name>"` and any quoted
mention), BUDs at `b5bd280`, pinned Buzz source (crates, desktop, web,
admin-web, mobile), and Buzz issue/PR titles.

* **`declared-model-artifact`** — NIPs 0, BUDs 0, Buzz source 0. GitHub issue/PR
  search returned only tokenized word matches with unrelated titles; the exact
  phrase returned 0.
* **`model-artifact`** — NIPs 0, BUDs 0, Buzz source 0 as a tag name. The phrase
  appears only as ordinary prose in Buzz threads about speech-model files
  (#5194; #299, which describes an STT file "added to SHA-256 verification").
  That is not a tag collision.
* **`buzz:declared-model-artifact`** — no hits. However, `buzz:` is Buzz's own
  in-tree namespace (`buzz:mention-snapshot`, `buzz:custom-emoji`,
  `buzz:config-nudge`, and others). NIPs have no general namespace convention for
  tag names; the only colon-bearing tag names are NIP-85's `<kind>:<metric>`
  scheme (85.md:118-127).
* **`model`** (control) — no NIP tag of that name. NIP-90 uses `model` as a
  free-text key inside `["param", "model", …]` (90.md:80). Buzz uses `model` as a
  configuration field name (e.g. `agentManagement.test.mjs:50`) and builds no
  Nostr tag named `model` in non-test source.

## 7. Candidate table

| Candidate | Indexing class | Existing meaning / collision | Declared-only clarity | Artifact clarity | Unaware behaviour | Namespace / ownership implication | Expansion safety | Disposition |
|---|---|---|---|---|---|---|---|---|
| `declared-model-artifact` | non-indexed: multi-character, so no NIP-01 filter key | none found | explicit: "declared" | explicit: "artifact", not a name | preserved but uninterpreted on original events; dropped on edit overlays (Gate 1 qualification, not new) | none; a descriptive name claiming no owner | leaves `effective-…`, `peer-served-…` and `execution-attested-model-artifact` free | **VIABLE** |
| `model-artifact` | non-indexed | none as a tag; prose use only | **fails**: without "declared" it reads as *the* model artifact of the event | explicit | as above | none | **fails**: appropriates the unqualified term contract §9 reserves | INCOMPATIBLE |
| `buzz:declared-model-artifact` | non-indexed | none | explicit | explicit | as above | **falsely implies Buzz ownership**: `buzz:` is Buzz's in-tree namespace and Buzz has not adopted this relationship | fine | INCOMPATIBLE |
| `model` (control) | non-indexed | NIP-90 free-text model *name* key; Buzz config name field | **fails**: says nothing about declaration | **fails**: reads as a model-name field — the §8 mutable-name misreading | as above | none | **fails**: claims the broadest possible term | INCOMPATIBLE |

## 8. Selection

```text
SELECTED CARRIER: declared-model-artifact
```

It satisfies every selection condition:
1. The indexing class was decided first: NON-INDEXED BY DESIGN.
2. No collision was found in NIPs, BUDs, Buzz source or Buzz titles.
3. It implies neither effective nor execution provenance.
4. It denotes artifact identity, not a model name.
5. Known Buzz consumers do not reinterpret it; Gate 1's edit-overlay limitation
   applies unchanged.
6. It makes no namespace or ownership claim.
7. No other examined candidate survived.

**Why not a lexical variant.** Word-order or synonym variants such as
`model-artifact-declaration` would score identically on N1–N8, and choosing
among them could otherwise only be taste. The selected form is not arbitrary: it
is the term the committed contract already uses in its title, "declared
model-artifact binding", written in the hyphenated lowercase form
existing NIP tag names use (for example `content-warning`, `parent-commit`,
`merge-base`). The singular describes one relationship instance. It says nothing
about event-level cardinality (§10).

**Status of the name.** This is a project-level public name selected for the
Phase 2A artifact. It claims no upstream adoption, no NIP number and no
ownership by Nostr, Buzz, Blossom or the UOR Foundation.

## 9. Exact selected shape

```text
["declared-model-artifact", "<64-lowercase-hex-sha256>"]
```

Meaning, and nothing more:
* the event's author declares the identified artifact as a model artifact
  associated with the author's declared model configuration;
* the declaration is **not** effective provenance;
* the declaration is **not** execution attestation;
* the digest is SHA-256 over the artifact's complete literal bytes;
* malformed forms remain governed by Gate 4A. Every INVALID class there still
  applies, and an invalid instance is not a Scope A declaration.

**Naming-semantics check against a false assertion (Gate 3 §4).** Take a
well-formed declaration whose digest identifies unrelated bytes:

```text
["declared-model-artifact", SHA256(unrelated_document)]
```

An aware verifier MUST read it as *the author declared these bytes as a model
artifact associated with the author's declared model configuration*. It MUST NOT
read it as *these bytes have been established to be a model artifact*. The word
"declared" in the name places the claim with the author, not with the bytes. The
carrier name therefore preserves the contract's authenticity-versus-truth
distinction (contract §2, §5): the signature authenticates the declaration, a
digest match establishes only that the bytes correspond, and neither establishes
the truth of the asserted relationship. Nothing is added to encode this; it comes
from the carrier's normative semantics.

## 10. Remaining open questions

* **G1-1 edit semantics** — open. Naming does not decide inheritance,
  replacement or redeclaration across edits.
* **Event-level cardinality** — open. The singular name reflects one instance
  only, not a limit per event.
* **Declared configuration vs transmitted request** (contract §12(2)) —
  untouched.
* **Extension syntax** for model name, referent type and retrieval hints — not
  as trailing elements (Gate 4A); otherwise undecided.
* **Discovery.** If relay-level artifact lookup is ever required, it is a
  separate, later decision. Gate 4B does not foreclose it; it declines to create
  it without a requirement.
* **UNDETERMINED:** ecosystem relays' treatment of unknown multi-character tags
  beyond Buzz, which NIP-01 does not address (Gate 1); and broader
  relay-indexing cost.

## 11. Contradiction gate

* **Changes the semantic contract, Gate 1, 2, 3 or 4A?** No. Only `<carrier>`
  is chosen. Every frozen row in §1 is unchanged.
* **Requires another field?** No.
* **Requires indexing for verification?** No. Verification remains local
  (Gate 4A).
* **Introduces active unaware-consumer behaviour?** No new behaviour: the name
  has no existing consumers (§6). Gate 1's edit-overlay drop is a known
  limitation carried forward, not introduced here.
* **Creates namespace ownership claims not already authorized?** No. The
  selected name is un-namespaced, and the one namespaced candidate was rejected
  on exactly this ground.
