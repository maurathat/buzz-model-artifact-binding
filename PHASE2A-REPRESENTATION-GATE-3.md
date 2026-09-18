# Buzz Phase 2A — Representation Gate 3: Minimum Concrete Encoding

**Status at writing: review draft, prepared outside Git.** An encoding-family
selection gate. It selects an abstract encoding shape only. It chooses no
public tag name, no digest algorithm, no textual digest encoding and no
validation rules, and it implements nothing, creates no test vectors, modifies
nothing in Buzz and opens nothing upstream.

## 1. Committed basis

`buzz-model-artifact-binding` HEAD `bddb89a5960b79d9f35d4b21a76377b2d6784bac`:

| File | sha256 (committed blob) |
|---|---|
| `PHASE2A-SEMANTIC-CONTRACT.md` | `94fc88e53759d83083ee679c8189f6b54c3d08cc19d6caa1f557945d5ab7cbc5` |
| `PHASE2A-REPRESENTATION-GATE-1.md` | `6177d39cc9b96a59f1184132d3bc7fc4d7cfeb06f696c48868e6544dd5a2568d` |
| `PHASE2A-REPRESENTATION-GATE-2.md` | `0c2b1dce38aa1e70c368eb79e6c9d14dffd3e3a0d003eaf6a54ef9a8853c5dba` |

**Frozen input (Gate 2).** The declarant is supplied by the signed event and is
not duplicated. The following must be knowable to a conforming verifier:
relationship semantics, content digest value, digest algorithm semantics.
Referent type is MAY; model name and retrieval hints are EXTENSION; per-instance
scope value, per-instance algorithm identifier, cardinality and G1-1 are
UNRESOLVED; direct/transitive depth and all effective, peer, execution and
runtime information are not carried.

**Binding exclusions (Gate 1).** `imeta` (INCOMPATIBLE); existing `x` semantics
and the BUD-09 / NIP-56 third-position vocabulary (structural precedent only);
`ox` (asserts transformation history); `a`/`e` indirection (not byte-local).
None is reopened.

**Event boundary.** Gate 3 selects an encoding for a declaration on the
immutable carrying event. It does not decide whether an edit inherits, replaces
or redeclares that relationship. G1-1 stays open, and nothing here claims the
encoding survives the kind-40003 edit overlay, which Gate 1 found drops unknown
tags.

## 2. Four-candidate comparison

Abstract shapes only; placeholders are not names.

| Candidate | Predicate location | Algorithm location | Serialized elements | Variable axes | New invalid states | Gate 1 collision risk | Unaware-consumer effect | Extra info beyond Gate 2 minimum |
|---|---|---|---|---|---|---|---|---|
| **1** predicate-specific / fixed algorithm — `["<scope-a-tag>", "<digest>"]` | carrier definition | carrier definition | 2 | 1 (digest) | no malformed or variable-axis states beyond the shared baseline (§4) | lowest: one positional value, under a carrier whose meaning is exactly Scope A. Reuses the `x`-like *shape* only, which Gate 1 permits as structural precedent | Buzz: unchanged from Gate 1 — preserved but uninterpreted on the original event (reasoning: nothing in Gate 1's findings keys on arity). Normative: NIP-01 silent | **none** |
| **2** predicate-specific / explicit algorithm — `["<scope-a-tag>", "<algorithm>", "<digest>"]` | carrier definition | per instance | 3 | 2 | unknown algorithm; algorithm/digest-length mismatch; identifier spelling variants | low, plus one more positional slot another mechanism could later assign meaning to | Buzz: same as 1. One more field for any future consumer to misparse | per-instance algorithm identifier (Gate 2: UNRESOLVED, not MUST) |
| **3** generic / explicit predicate / fixed algorithm — `["<relationship-tag>", "<predicate>", "<digest>"]` | per instance | carrier definition | 3 | 2 | unknown predicate; predicate unsupported by this version; predicate spelling variants; **a declared digest labelled with a stronger predicate** | **recreates the Gate 1 pattern**: an owned type-vocabulary slot on a shared carrier (cf. the NIP-56 / NIP-5A third-position collision) | worse than 1: the declared/effective distinction becomes one string inside a carrier that would also host stronger claims — the §8 over-reading risk | per-instance predicate (Gate 2: UNRESOLVED, not MUST), plus a predicate vocabulary |
| **4** generic / explicit predicate / explicit algorithm — `["<relationship-tag>", "<predicate>", "<algorithm>", "<digest>"]` | per instance | per instance | 4 | 3 | the union of 2 and 3, plus predicate × algorithm combinations | as 3, with two owned-vocabulary slots | as 3 | both of the above |

## 3. Field-count accounting

The declarant is excluded; it comes from the event's key and signature. The
carrier identifier counts as a serialized element, but it is carrier
identification, not relationship payload.

| Candidate | Serialized total | Carrier identification | Relationship payload | Fixed by carrier definition | Supplied per instance | Independent semantic axes |
|---|---|---|---|---|---|---|
| 1 | 2 | 1 | 1 | predicate + declared scope + algorithm | digest | **1** |
| 2 | 3 | 1 | 2 | predicate + declared scope | algorithm, digest | 2 |
| 3 | 3 | 1 | 2 | carrier genus + algorithm | predicate, digest | 2 |
| 4 | 4 | 1 | 3 | carrier genus only | predicate, algorithm, digest | 3 |

Only candidate 1 has no serialized degree of freedom that Gate 2 did not
require.

## 4. Invalid-state analysis

Whether each candidate **creates** a state at all. Validation rules are not
specified here.

**Baseline, shared by all four:** empty digest; malformed or wrong-length digest;
non-canonical digest representation; extra trailing elements. These follow from
carrying a digest in a Nostr tag at all, and the next checkpoint must handle
them whichever candidate is chosen.

**Created only by an explicit algorithm (2, 4):** unknown algorithm;
algorithm/digest-length mismatch; spelling variants of the same algorithm; the
need for an identifier vocabulary. The spelling-variant state is not
hypothetical — labelled reasoning from this project's own history: the Phase 1
scorer needed a dedicated fix because `sha-256:` and `sha256:` were treated
differently (harness changelog 0.3.2/0.3.3, audit finding A-03b).

**Created only by an explicit predicate (3, 4):** unknown predicate; predicate
unsupported by this version; spelling variants; and one *semantic* invalid state
the others cannot express — a digest the author only declared, carried under a
predicate asserting something stronger. In candidate 1 that state is
unrepresentable: the carrier means exactly Scope A.

States that cannot be written need no validator. Candidate 1 creates no
malformed or variable-axis states beyond the baseline.

**Semantic falsehood, shared by all candidates — distinct from malformed
encoding.** A well-formed declaration may identify bytes that are not in fact a
model artifact associated with the author's declared model configuration — for
example a digest of an unrelated document. This is not a malformed encoding and
generally cannot be rejected by syntax validation. The signature establishes
that the author made the assertion; digest verification establishes the
bytes-to-digest correspondence; neither independently establishes the truth of
the asserted relationship (semantic contract §2 and §5). It is possible under
all four candidates equally, is not a serialized invalid state, and is not
unique to Candidate 1.

## 5. Unaware-consumer analysis

**Normative.** NIP-01 says nothing normative about unrecognised tags (Gate 1 §3).
No candidate is normatively guaranteed to be ignored. This applies equally to
all four and separates none of them.

**Buzz at the pinned commit (Gate 1 findings, not re-surveyed).** Relay kind-9
ingest applies no tag-name allowlist, and its two tag validators are scoped by
name (`link-preview`, `imeta`), so an unknown tag passes untouched; storage and
delivery preserve tag values and ordering as data; the client reads tags by
positive-name lookup with no exhaustive enum. None of those findings keys on the
*number* of elements in an unknown tag. So, as reasoning, adding elements
(candidates 2–4) changes no known Buzz behaviour, and the Buzz surface does not
separate the candidates. The kind-40003 edit-overlay drop applies to all four
equally.

**Future semantic collision.** This is where they separate. Gate 1's central
finding was that positional slots attract owners: `x`'s value slot has eight
claimants, and its third slot two, with disjoint vocabularies. Every additional
positional element is another slot a later mechanism can assign meaning to.
Candidate 1 exposes one value position; 2 and 3 expose two; 4 exposes three.
Candidates 3 and 4 go further and deliberately create a *type-vocabulary* slot —
the exact structure Gate 1 found already owned twice in `x`. A new carrier name
reduces collision risk but does not eliminate it; fewer slots reduce it further.

## 6. Minimality test

**Remove each per-instance field.**

* Candidate 1, digest → loses the content digest value (Gate 2 MUST). Kept.
* Candidates 2 and 4, algorithm identifier → loses nothing Gate 2 marked MUST
  *if* the carrier definition fixes the algorithm. Unnecessary.
* Candidates 3 and 4, predicate → loses nothing Gate 2 marked MUST *if* the
  carrier's own definition is the Scope A predicate. Unnecessary.

**Fix each variable axis in the carrier definition.**

* *Fixing the algorithm* violates no committed requirement. Contract §5(2)
  requires identity "under the stated digest semantics"; §12(3) left open *how*
  they are stated. A normative carrier definition is a statement of them. Gate 2
  §6 records that a representation-fixed algorithm meets the algorithm-semantics
  MUST, and Gate 2 constraint 5 (no inference from the value's shape) is
  satisfied because the function comes from the carrier definition. Per-instance
  agility therefore needs its own justification, and none exists in the
  committed record: agility was left open, never required.
* *Fixing the predicate* violates no committed requirement. Contract §9 says
  Scope A is "the first term in a possible provenance vocabulary"; it does not
  require later terms to share Scope A's wire carrier. Gate 2 shows a per-instance
  predicate is needed only if a carrier is shared. Sharing is not required, so the
  per-instance predicate has no independent justification.

**Add one optional element (adversarial).**

* *Model name* (Gate 2: EXTENSION): adds a mutable label and the §8 misreading
  risk, and strengthens nothing in the relationship. Out.
* *Referent type* (Gate 2: MAY): the digest already identifies a manifest or a
  weight-bearing object without changing the encoding; a verifier derives the
  class from the bytes and records its own resolution depth. Adding it
  strengthens nothing Scope A guarantees. Out of the minimum.

**Convenience fields excluded, none forced by any committed requirement:** model
name, referent type, URL, Blossom server, provider, path, direct/transitive
flag, timestamp, version field, peer, effective artifact, execution receipt. No
candidate needs any of them to work. Timestamp is excluded because the frozen
contract requires no separate temporal claim for Scope A. The carrying event
retains its ordinary Nostr event metadata, whose semantics are not extended by
this relationship.

## 7. Selection

Applying the rule — *the candidate with no unnecessary serialized degree of
freedom that still carries every Gate 2 MUST and violates no Gate 1 exclusion*:

```text
SELECTED — Candidate 1
predicate-specific carrier  +  digest
```

**Not a tie.** Candidates 1 and 2 are not semantically equivalent: 2 adds a
degree of freedom — and its own class of invalid states — that no committed
requirement justifies. Candidate 3 fails more than minimality: it re-creates the
owned-type-slot collision Gate 1 identified and makes the declared/effective
distinction a per-instance string. Candidate 4 inherits every cost of 2 and 3.

**The selected family, abstractly:**

| Element | Role | Supplied by |
|---|---|---|
| carrier identifier | names the carrier. Its normative definition *is* the Scope A predicate: author-declared model artifact associated with the author's declared model configuration, declared not effective not executed. It also fixes one digest algorithm | the representation definition |
| digest value | content identity of the declared artifact, under the carrier's fixed algorithm | per instance |
| declarant | who declares | the carrying signed event — **not** a tag element |

**Cost accepted by this selection, stated rather than hidden:** if the fixed
algorithm must change, migration requires a new or versioned representation
definition rather than a per-instance algorithm value. Gate 3 does not decide
how that versioning is expressed. That is the price of no per-instance agility,
and it is the only cost the comparison surfaced.

**What the fixed algorithm must satisfy** (needed only to confirm candidate 1 is
valid; the algorithm is not chosen): a cryptographic, collision-resistant hash
computed over the artifact's exact bytes, never over a name or reference string
(contract §3); a fixed output length; computable locally, with no service or
registry (contract §3, §5).

## 8. Decisions resolved

| Gate 2 UNRESOLVED / contract open item | Resolution |
|---|---|
| Per-instance scope/predicate value (Gate 2) — contract §12(5), scope-declaration mechanics | **Not carried.** The predicate and declared scope live in the carrier's normative definition |
| Per-instance algorithm identifier (Gate 2) — contract §12(3), digest-algorithm agility | **Not carried.** The algorithm is fixed by the representation definition. If it must change, migration requires a new or versioned representation definition rather than a per-instance algorithm value; how that versioning is expressed is not decided here |
| Contract §12(6) encoding — *family only* | predicate-specific carrier + digest, carried as a tag on the immutable carrying event |

## 9. Decisions remaining open

* **Final public tag name**, including whether it is single-letter (and so
  relay-indexed) or multi-character or namespaced. Gate 1's crowded `x`
  namespace and Buzz's in-tree `buzz:mention-snapshot` precedent are inputs,
  not conclusions.
* **Which digest algorithm** the carrier fixes.
* **Textual digest encoding**, and canonical versus non-canonical handling.
* **Malformed-input behaviour** for the baseline states in §4, including extra
  trailing elements.
* **Event-level cardinality.** Here one tag = one declaration for comparison
  only. Nothing is said about zero, one or many per event, and no list container
  is introduced.
* **G1-1 edit semantics** — open, narrowed as recorded in Gate 2.
* **Extension syntax** for referent type, model name and retrieval hints.
* **Declared configuration vs transmitted request** (contract §12(2)) —
  untouched.
* Effective, peer and execution provenance — outside Scope A, not designed.

## 10. Contradiction gate

* **Contradicts the semantic contract?** No. Fixing the algorithm in the carrier
  definition is one way of *stating* digest semantics, which §5(2) requires and
  §12(3) left open. A Scope A-only carrier is consistent with §9, which reserves
  room for later terms without requiring them to share a carrier.
* **Contradicts Gate 1?** No. The selected shape reuses the `x`-like structure
  only as structural precedent, which is exactly the disposition Gate 1 gave it.
  It reuses no existing tag name, adds no type slot and carries no location.
* **Contradicts Gate 2?** No. It carries exactly the three MUST items and the
  envelope-supplied declarant. It resolves two Gate 2 UNRESOLVED items *against*
  adding fields, so nothing is promoted to a mandatory serialized element.
* **Changes a prior candidate disposition?** No. Gate 1's candidate D ("new
  semantic tag on an existing structural shape") is the family candidate 1
  belongs to. It is now selected at the level of family — not as a named tag —
  on minimality grounds, not merely as a surviving control. Its Gate 1
  qualifications still hold: no normative safe-degradation guarantee, and the
  edit overlay drops it.
* **Adds information Gate 2 did not authorize?** No. Candidate 1 adds none.
