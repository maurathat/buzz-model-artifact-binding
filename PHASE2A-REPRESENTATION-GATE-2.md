# Buzz Phase 2A — Representation Gate 2: Minimum Information Model

**Status at writing: review draft, prepared outside Git.** Information model
only. No tag name, no Nostr array, no field order, no digest encoding, no
NIP/BUD number, no implementation, nothing upstream. Candidate D is **not**
selected; this model is independent of which representation eventually carries
it.

## 1. Basis and scope

Derived from the two committed Phase 2A artifacts at
`buzz-model-artifact-binding` HEAD `2cb6000f2b36db0b9633c4bb16b1aa9e485509a7`:

| File | sha256 (committed blob) |
|---|---|
| `PHASE2A-SEMANTIC-CONTRACT.md` | `94fc88e53759d83083ee679c8189f6b54c3d08cc19d6caa1f557945d5ab7cbc5` |
| `PHASE2A-REPRESENTATION-GATE-1.md` | `6177d39cc9b96a59f1184132d3bc7fc4d7cfeb06f696c48868e6544dd5a2568d` |

Commit `2cb6000f` changed only the two antecedents' status lines and added a
marked clarification to contract §11 (see §8 below); it did not change Scope A's
meaning. Gate 1 itself still records that it evaluated the earlier contract blob
`dc4f93a9…`, and that remains its historical basis.

Governing distinction, unweakened: `DECLARED ≠ EFFECTIVE ≠ EXECUTED`.
The verification boundary is the contract's §5: a verifier establishes at most
that (1) the author made and signed the declaration, (2) the declaration
identifies content under stated digest semantics, (3) candidate bytes match or
do not.

**Method.** One relationship instance is modelled abstractly. Each candidate
element is tested by one question: *if absent, can a verifier still interpret
and verify the Scope A declaration without guessing?* Semantic information is
kept separate from serialized fields: a representation's normative definition
can itself carry meaning, so "the information is required" does not imply "a
per-instance field is required".

## 2. Information-element matrix

| Information element | Classification | Why | What becomes ambiguous if omitted? | Asserted / derived |
|---|---|---|---|---|
| **Declarant** (the subject) | **MUST** — supplied by the carrying event, not a payload element | Contract §2: the subject is the keyholder that signed the event; §5(1) cannot be established without it | Who made the assertion; §5(1) becomes impossible | **Supplied by envelope** — the carrying event's signing key and signature. Not re-stated in the payload |
| **Relationship semantics** — that the digest names a *declared* model artifact associated with the author's declared model configuration, with the declared-not-effective-not-executed scope | **MUST** as information | Contract §1, §2, §6. Gate 1 §3 shows the failure without it: a bare digest (`x`) has eight claimants and two incompatible readings | Everything. A digest with no predicate is not a Scope A declaration; an unaware or aware reader can attach any of several existing meanings | **Asserted** by the author |
| **Per-instance explicit scope/predicate value** (as distinct from the information above) | **UNRESOLVED** | A representation whose normative definition *is* the Scope A predicate supplies the information with no per-instance value. A per-instance value becomes necessary only if one carrier is shared by several predicates (contract §9's future effective / peer-served / execution-attested terms). Which applies is an encoding decision | If the carrier is exclusive to Scope A: nothing. If shared: which predicate the instance asserts | Asserted, if carried |
| **Content digest value** | **MUST** | Contract §3: the declaration MUST identify the artifact by a cryptographic content digest; §5(3) is a comparison against it | What artifact is declared; §5(3) cannot be performed | **Asserted** |
| **Digest algorithm semantics** — which function the value is interpreted under | **MUST** as information | Contract §5(2): identity is "under the stated digest semantics". "Match" is undefined without the function. Gate 1 §3: values of identical shape carry different functions (NIP-35 BitTorrent infohash vs NIP-94 SHA-256) | Whether candidate bytes match; the verifier would have to guess the function from the value's shape, which Gate 1 shows is unreliable | Must be **known to any conforming verifier** — from the instance or from the representation's definition |
| **Per-instance algorithm identifier** | **UNRESOLVED** | If the representation (or a version of it) normatively fixes the algorithm, the identifier is redundant and nothing is ambiguous. If algorithm agility is required, it becomes necessary. That is open question 3, which Gate 2 does not decide. Not promoted to MUST for explicitness | Only under agility: which function applies to this instance | Asserted, if carried |
| **Referent type** (manifest vs weight-bearing object) | **MAY** | The declaration identifies bytes X exactly whether or not X's class is stated, and §5(1)–(3) do not depend on it. Contract §4 makes transitive establishment conditional ("MAY establish"), so its absence removes nothing Scope A guarantees. If carried it is itself only an author assertion; a verifier must still inspect the bytes before resolving a manifest | Nothing in the declaration. Only a convenience is lost: the verifier determines X's class by inspecting or resolving X | **Asserted** if carried; otherwise **derived** by inspection |
| **Direct / transitive depth** | **OUTSIDE SCOPE A** as a carried element | Contract §4: transitive binding is established "by resolving the graph, not by reading the event", and "the contract must keep visible what is signed into the event versus what a verifier establishes". An author-asserted depth would sign a verifier-established fact into the event, and an asserted "transitive" invites exactly the misreading §4 forbids (the event binding weight bytes) | Nothing. Depth follows from which object was named and how far the verifier resolved it. Confirmed by the contract's §11 clarification (commit `2cb6000f`): the declaration need not carry direct/transitive-depth fields | **Derived** by the verifier; never asserted |
| **Model name** | **EXTENSION** | Contract §3: a name is not content identity, and a name alone is insufficient. It is not required to interpret the declaration or for §5(1)–(3), and it must take **no part** in bytes-to-digest verification. It can serve as human-readable or correlation metadata (for example against existing model naming), but it stays mutable and dependent on a naming authority, and under Mesh it may be the virtual placeholder `mesh` (§2a). It is not an excluded Scope B claim — a display label asserts neither selection nor execution — so it is not OUTSIDE SCOPE A. It is deferred rather than MAY because contract §8 forbids an unaware reading of the reference as a mutable model name, and a name is the most direct route to that reading. If ever carried: not identity-bearing, not structurally confusable with the declared artifact identity, and implying no effective selection or execution | Nothing for verification or interpretation. Human readability and correlation are lost | Asserted, if ever added |
| **Location / retrieval hint** (URL, Blossom server, repository, path, provider) | **EXTENSION** | Contract §5: identity ≠ retrievability ≠ availability; the verifier may already hold the bytes. Not identity-bearing, so never MUST. Deferred rather than MAY because Gate 1 found location-bearing constructs trigger unprompted fetches in real Buzz consumers (`timelineImagePreload.ts:19-24,49-54`) | Nothing for identity or verification | Asserted, if ever added |
| **Event-level cardinality** | **UNRESOLVED** | Not an element of an instance. One instance is fully specified here without deciding how many an event may carry. Contract §12(1) left it open; nothing here requires deciding it. Mesh's multiple effective artifacts do not imply multiple declared artifacts (contract §7, §12(1)) | Nothing within an instance | Rule about events, not about instances |
| **Edit semantics** (G1-1) | **UNRESOLVED** | See §5. The minimum instance model does not depend on it | Nothing within an instance | — |

**Excluded from the information model entirely: digest encoding.** Hex, base64,
multibase and similar are syntax. None changes which bytes are identified, so
none is an information element. Deferred to Gate 3.

## 3. Minimum semantic payload

In abstract terms, one relationship instance conveys exactly this information:

1. **The predicate** — that the identified artifact is declared by the author as
   a model artifact associated with the author's declared model configuration,
   with the declared (not effective, not executed) scope. Conveyed by the
   representation's normative definition or by an explicit per-instance value;
   which is UNRESOLVED.
2. **The content identity** — a content digest value.
3. **The digest function** — under which the value is interpreted, knowable by
   any conforming verifier without inference from the value itself, whether
   carried per instance or fixed by the representation's definition or version.

Supplied by the carrying event, not by the payload: **the declarant**, via the
event's signing key and signature, which also covers the payload's integrity.

Everything else is MAY (referent type), EXTENSION (model name, retrieval
hints), OUTSIDE SCOPE A (asserted depth, all Scope B concepts) or UNRESOLVED
(per-instance scope value, per-instance algorithm identifier, cardinality, edit
semantics).

## 4. Inventory

**MUST** — declarant (supplied by envelope); relationship semantics; content
digest value; digest algorithm semantics.

**MAY** — referent type.

**EXTENSION** — model name; location / retrieval hints.

**UNRESOLVED** — per-instance scope/predicate value; per-instance algorithm
identifier; event-level cardinality; edit semantics.

**OUTSIDE SCOPE A** — asserted direct/transitive depth, and the Scope B
concepts below, each of which, if added, creates a *different* claim
rather than strengthening this one. The author generally cannot know most of
them either: the Mesh probe found the effective artifact is never returned to
the agent.

| Concept | Why it is outside Scope A | Contract basis |
|---|---|---|
| effective model | a claim about what downstream resolution chose | §2 (never asserted), §6(2), §9 (reserved term) |
| effective artifact digest | identity of the effective artifact, not the declared one | §6(2), §7 |
| router-selected artifact | downstream selection | §6(1) |
| peer identity | compute participants are never asserted, named or bounded | §2, §6(5) |
| peer-served artifact | serving is a peer act, not an author declaration | §6(6), §9 (reserved term) |
| execution receipt | execution attestation | §6(10) |
| runtime attestation | runtime trustworthiness and attestation | §6(9), §6(10) |
| load proof | that the artifact was loaded | §6(3) |
| inference participation | that it participated in inference | §6(4) |
| result-to-artifact execution binding | that it produced the content | §6(7) |

### Information-model constraints recorded for Gate 3

These create over-reading risk regardless of syntax:

1. The declared artifact identity must not be **structurally confusable with a
   model name**. If a name is ever carried (EXTENSION), it must be visibly
   separate from the digest, take no part in verification, and imply no
   effective selection or execution (contract §3, §8).
2. No term may imply selection or effectiveness; Scope A may not appropriate
   unqualified *model artifact of this event*, *model provenance* or *effective*
   (contract §9).
3. **Location must never be part of identity.** A retrieval hint, if ever
   introduced, must be separable and must not be fetch-triggering (Gate 1,
   `imeta` pre-warm).
4. No runtime or execution state inside the declaration (contract §6).
5. The digest function must not be inferable **only** from the value's shape
   (Gate 1 §3: same-shape values, different functions).
6. If referent type is carried, it must not reuse an existing owned type
   vocabulary (Gate 1 §3: the third-position slot is owned twice).
7. The declaration must not be positioned or phrased so it reads as describing
   the **message content** (contract §6(7)). See §5.

## 5. Edit-semantics disposition — G1-1

```text
G1-1 REMAINS OPEN — narrowed
```

**What the frozen contract settles.** Option B — *the declaration semantically
follows the edited or displayed message* — is **excluded by the contract**, not
by any implementation. The contract never associates the declared artifact with
message content: the object is "a model artifact associated with its declared
model configuration" (§1), and the relationship expressly does not establish
"that it produced the event's content" (§6(7)). A declaration that is not about
the original content cannot follow edited content. `applyEditTagOverlay`
behaviour played no part in this.

**What it does not settle.** Between A (the declaration belongs permanently to
immutable original event E) and C (an edit wanting a declaration must carry its
own), the deciding question is one the contract is silent on:

> Is "declared model configuration" scoped to the **authoring act of the
> carrying event** — the configuration under which that event was made — or is
> it a **standing claim** about the author's configuration?

If event-scoped, A holds for E, and an edit is a separate signed act that
carries a declaration only if it makes its own — C then follows from A rather
than competing with it. If standing, E's declaration could be read as persisting
across later events, and edits raise questions of supersession instead.

**Required to close G1-1:** a semantic decision on the temporal/event scope of
the declared configuration. No further evidence would settle it; it is a
definition. That decision would extend the frozen contract, and Gate 2 does not
make it. It does not force any field into the minimum instance model.

## 6. Cheap falsification result

**MUST elements, removed one at a time:**

| Removed | Declaration still unambiguous? | Bytes still locally verifiable? | Outcome |
|---|---|---|---|
| Relationship semantics | No — reverts to a bare digest with eight competing readings (Gate 1 §3) | Bytes match *something*, but it is not a Scope A declaration | **Kept MUST** |
| Content digest value | No — nothing identifies the artifact | No — §5(3) has nothing to compare | **Kept MUST** |
| Digest algorithm semantics | No — the value's meaning is unknown | No — "match" is undefined; the verifier would have to guess the function | **Kept MUST** |
| Declarant | No — no assertion has an author | §5(1) impossible | **Kept MUST**, supplied by envelope |

**Downgrades the test forced** — each would have been MUST on an
"explicit is safer" instinct:

* **Per-instance algorithm identifier → UNRESOLVED.** A representation-fixed
  algorithm satisfies the MUST without it.
* **Per-instance scope value → UNRESOLVED.** A predicate-defining representation
  satisfies the MUST without it.
* **Referent type → MAY.** Removing it leaves the declaration exact and §5(1)–(3)
  intact.

**OUTSIDE SCOPE A elements, added one at a time:** every Scope B concept in §4
creates a different claim (downstream, peer or execution), not a stronger
version of this one, so all stay outside. **Asserted depth** creates a claim the
contract assigns to the verifier (§4 and the §11 clarification), so it stays
outside.

**Model name, reclassified.** Added hypothetically, a name creates a separate,
mutable label association. That is *not* an excluded Scope B claim, so it is not
OUTSIDE SCOPE A. Removed, it leaves the declaration and §5(1)–(3) intact, so it
cannot be MUST. It is held at EXTENSION, not MAY, because of the §8 misreading
risk (see §2).

## 7. Open-question status

| # | Question | Status | Basis |
|---|---|---|---|
| 1 | Declaration cardinality | **UNCHANGED** | One instance is fully specified without it; nothing here requires deciding it |
| 2 | Declared configuration vs transmitted request | **UNCHANGED** | The minimum payload carries only the declared side. Adding the transmitted request (under Mesh, possibly `mesh`) would create a separate request-side claim; whether that warrants its own term is not advanced here |
| 3 | Digest-algorithm agility | **NARROWED** | Algorithm *semantics* are MUST; a per-instance *identifier* is needed only if agility is required. The two are separable: a representation- or version-fixed algorithm meets the MUST |
| 4 | Referent typing | **NARROWED** | Not MUST for the minimum model (MAY). Whether and how to carry it is a Gate 3 choice, bounded by Gate 1's position-3 collision |
| 5 | Scope-declaration mechanics | **NARROWED** | The predicate-and-scope *information* is MUST. Whether it rides on the representation's definition or on a per-instance value depends on whether future predicates share the carrier |
| 6 | Encoding | **UNCHANGED** | Deliberately untouched |
| 7 | G1-1 edit semantics | **NARROWED** | Option B excluded by contract §1 and §6(7); A vs C turns on the undecided temporal/event scope of the declared configuration |

Nothing is **NEWLY BLOCKING** for the information model or for Gate 3. The
temporal-scope decision blocks only the resolution of G1-1.

## 8. Contradictions and UNRESOLVED findings

**Contradiction gate:**

* **Contradicts the frozen semantic contract?** No. The one wording tension
  this gate surfaced has been **resolved in the contract**, not merely
  interpreted here. Contract §11 said "Recording the referent and the resolution
  depth carries the distinction", which could be read as requiring those fields
  in the declaration. Commit `2cb6000f` added a marked clarification with no
  change of meaning: "recording" is the verifier's record of what object was
  declared and what was later established through verified resolution, and the
  declaration need not carry referent-type or direct/transitive-depth fields
  (§4). Referent type therefore stays **MAY**, and asserted depth stays
  **OUTSIDE SCOPE A** as a carried element, derived by the verifier.
* **Requires amending Gate 1?** No.
* **Changes any Gate 1 candidate disposition?** No.
* **Makes candidate D non-viable, even as a control?** No. Nothing in the
  minimum payload is beyond what D's shape could carry. D is still not selected.

**Something Gate 1 assumed that Gate 2 narrows.** Gate 1 phrased G1-1 as whether
the declaration "remains semantically associated with the edited content". That
phrasing presupposes a content association the contract never makes (§1,
§6(7)). G1-1 remains a legitimate open question in the narrower form given in
§5. Gate 1 was not amended.

**UNRESOLVED, carried forward:** per-instance scope/predicate value;
per-instance algorithm identifier; event-level cardinality; G1-1, pending a
decision on the temporal/event scope of the declared configuration.
