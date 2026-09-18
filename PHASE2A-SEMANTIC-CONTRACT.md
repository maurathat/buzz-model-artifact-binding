# Buzz Phase 2A — Semantic Contract: declared model-artifact binding (Scope A)

**Status: draft for review. Not committed. Document-only.**
No tag, no tag name, no wire encoding, no implementation, no upstream activity.
This contract fixes what the relationship *means* before any syntax exists.

Governing distinction, not to be weakened anywhere below:

```text
DECLARED  ≠  EFFECTIVE  ≠  EXECUTED
```

Evidence base: the completed Phase 2 census (decision table; R2 unoccupied) and
the Mesh architecture probe. Phase 1 and its scorer are frozen and untouched.

## 1. One-sentence relationship definition

> The author of this signed event declares the referenced content-addressed
> artifact as a model artifact associated with its declared model
> configuration, and makes no claim about what any downstream party selected,
> loaded, served, or executed.

## 2. Subject / predicate / object

| Term | Definition |
|---|---|
| **Subject — event author** | The keyholder that signed the event. The declaration is an assertion *by* this party *about its own configuration*. The author is **not** asserted to be the party that selected the effective model, and **not** asserted to be a party that computed anything. |
| **Predicate — declares** | The author asserts that the referenced artifact is a model artifact associated with its declared model configuration. The event signature establishes that the author **made and signed that assertion**; it does **not** independently establish that the asserted relationship to the author's configuration is **true**, and nothing about downstream selection or execution follows from it. |
| **Object — declared artifact** | A content-addressed artifact, identified by a cryptographic **content** digest, named by the author as a model artifact of its declared configuration. Each declaration relates the event author to **one** referenced artifact; this contract does **not** determine how many such declarations an event may carry (§12 item 1). |
| *Not in the relationship* — **effective artifact(s)** | Whatever a downstream router, gateway or runtime actually resolved. May differ from the declared artifact; may be a set; may be layer-partitioned. Never asserted here. |
| *Not in the relationship* — **compute participant(s)** | Whatever peers held, loaded or ran anything. Never asserted, named, or bounded here. |

### 2a. "requested" vs "intended" — the evidence distinguishes them, so neither is adopted unqualified

The census brief asked which term the evidence supports. It supports **neither
as a synonym for the declaration**, because the two provably diverge:

* Under Buzz shared compute the value actually *transmitted* downstream is a
  virtual placeholder — the stored `auto` becomes the virtual model `mesh` —
  which names **no artifact at all**. So "requested artifact" is *false* in
  that case: no artifact was requested.
* The author-side configuration nevertheless exists and can name an artifact.

Therefore this contract uses **declared**, an author-side term, and treats
"requested" as a **narrower** notion that coincides with the declaration only
when the configuration is transmitted verbatim and names an artifact. Whether
a future term should separate *declared configuration* from *transmitted
request* is a real distinction this contract does not resolve; see §12.

This is deliberately the weaker reading. "Requested" and "intended" would both
imply more than the evidence supports in the shared-compute case.

## 3. Digest semantics

The declaration **MUST** identify the artifact by a cryptographic content
digest. A model name alone is insufficient.

```text
name    → identifies a mutable, resolvable LABEL; its referent can change
          without notice, and two parties can disagree about it
digest  → identifies BYTES under the stated digest algorithm; any party
          holding candidate bytes can decide match/no-match unaided
```

Two consequences, stated because the census found both violated in practice:

* A digest **of a name** is not a content digest. A hash computed over a
  canonical reference string identifies the label, not the bytes, and two
  byte-different artifacts under one label hash identically. Such a value does
  not satisfy this requirement.
* Possession or verification of a digest proves **neither execution nor
  selection**. It proves a bytes-to-identity correspondence and nothing else.

The contract must remain meaningful with **no registry lookup and no naming
authority**: the digest comparison is a local computation over bytes the
verifier already holds.

## 4. Direct versus transitive binding

Two distinct resolution depths of the *same* relationship. Not two
relationships, and not two evidence classes.

**Direct**

```text
event → digest → artifact bytes
```

Given the bytes, a verifier recomputes the digest and determines whether they
match the declared artifact identity.

**Transitive**

```text
event → manifest digest → verified manifest → cryptographically named
        weight-bearing objects
```

A manifest digest **directly binds only the manifest**. If the verified
manifest cryptographically names its weight-bearing objects, a verifier that
possesses or resolves those objects may establish the corresponding transitive
relationship — by resolving the graph, not by reading the event.

It is therefore false to say the event directly binds weight bytes when it
binds a manifest. The contract must keep visible what is signed into the event
versus what a verifier establishes downstream of it.

No new evidence classes are introduced by this contract.

## 5. Verifier knowledge — what is established, exactly

Given a valid signed event, a declared artifact digest, and candidate artifact
bytes, a verifier can establish **at most**:

1. the event author made and signed the declaration;
2. the declaration identifies content under the stated digest semantics;
3. the supplied bytes either match or do not match that digest.

Nothing further. In particular, not effective selection and not execution — and
not the **truth** of the assertion itself. A verifier establishes that the
author *asserted* the relationship, never that the asserted relationship to the
author's configuration objectively holds; only the author is in a position to
know that, and the signature authenticates the assertion rather than
corroborating it. (3) is unaffected: candidate bytes can still be checked
against the declared content digest, and that check is decisive.

No external authority or registry is required for (3).

**Verification is not retrieval.** That a verifier *can* check supplied bytes
does not mean the relationship guarantees those bytes are available,
retrievable, hosted, or findable. These five remain separate and must not be
collapsed:

```text
identity  ≠  retrievability  ≠  availability  ≠  provenance  ≠  execution
```

## 6. Explicit non-claims — the boundary of the claim, not caveats on it

These are constitutive. The relationship does **not** establish:

1. that the referenced artifact was selected downstream;
2. that it was the effective artifact;
3. that it was loaded;
4. that it participated in inference;
5. that any particular peer possessed it;
6. that any peer served it;
7. that it produced the event's content;
8. that the computation was correct;
9. that the runtime was trustworthy;
10. execution attestation of any kind.

Phrases the relationship therefore does **not** license, listed so they cannot
be reintroduced by paraphrase: *produced by, generated by, executed by, served
by, computed with, effective model, actual model, the model that generated this
response*. Each names a claim outside Scope A. Scope B — effective artifact
provenance and execution provenance — is out of scope and is not designed here.

## 7. Mesh compatibility test

The contract must stay true in both cases. This is the adversarial test, not an
illustration.

**Single-model / local case** — declared X, effective X. The declaration is
valid, **and does not prove the equality**. A verifier that confirms the digest
learns that the author declared X and that the bytes are X; it does not learn
that X was used. The Phase 1 configuration is this case.

**Mesh / shared-compute case**

```text
declared artifact
      ↓  downstream routing (resolves per request, outside the author)
effective artifact set {A, B, …}     ← may be several distinct models
      ↓
possibly layer-partitioned execution ← a model may itself be split across peers
```

The declaration remains semantically valid when `declared ≠ effective`, and
when **no single effective artifact exists**, because it never quantified over
effective artifacts at all. The author's assertion is about its own
configuration; the mesh result changes what is true downstream, not what the
author declared.

Wording test applied: any formulation that becomes false in the mesh case is
rejected. That is what eliminated "produced by", "served by", "effective", and
— per §2a — the unqualified use of "requested". Mesh is not solved here.

## 8. Unaware-verifier requirement (carried forward as a requirement on syntax)

A verifier that does not understand this relationship **must not be induced to
interpret it as a stronger existing relationship.** No encoding is chosen at
this stage; this is recorded as a constraint the later syntax must satisfy, and
it is an acceptance criterion, not a preference.

The eventual representation must not cause an unaware consumer to read a model
artifact as:

* **media**, merely because an existing media-carrying construct was reused;
* **execution attestation**;
* **effective-model provenance**;
* **an ordinary mutable model name**.

The census established that this failure mode is active rather than silent:
unaware consumers act on constructs they believe they recognise. Reuse of an
existing name can therefore be *worse* than a new name of identical shape.

## 9. Extensibility boundary

Scope A is the **first term** in a possible provenance vocabulary, not a closed
ontology. The vocabulary must leave conceptual room for later, distinct
relationships:

```text
declared artifact               ← Scope A, this contract
effective artifact              ← not designed
peer-served artifact            ← not designed
execution-attested artifact     ← not designed
```

Constraint accepted here: Scope A must not claim a term or a semantic position
that would make those later distinctions contradictory. Concretely, Scope A may
not appropriate unqualified *model artifact of this event*, *model provenance*,
or *effective* — each would have to be taken back to express a later term.

## 10. Revised Phase 2A design claim

The existing claim is **inaccurate after the Mesh findings** in three respects:
it does not mark the relationship as declared; "reference to a model artifact
digest" elides the manifest case from §4; and "verifiable" does not say what is
verified. Revised:

> An agent-authored Buzz event can carry a **typed, declared** reference to a
> content digest that the author identifies as a model artifact associated with
> its declared model configuration, such that any party holding candidate
> artifact bytes can verify **that the author signed the declaration and that
> the candidate bytes correspond to the declared digest** — with no registry
> lookup and no naming authority, without changing Buzz's actor-identity model,
> and without a verifier that does not
> understand the new typing misinterpreting the underlying standard Nostr
> reference. The reference binds the artifact it names: directly when that
> artifact is a weight-bearing object, and only transitively — by manifest
> resolution — when it is a manifest. It asserts nothing about effective
> selection or execution, and remains truthful when the effective artifact
> differs from the declared one or when no single effective artifact exists.

Each clause remains independently checkable. No adoption criterion is added, and
no effective-provenance or execution claim is introduced.

## 11. A-04 disposition

```text
A-04 NOT REQUIRED FOR PHASE 2A
```

A-04 asked whether a digest under a model-declaring key should remain
`WEIGHTS_DIGEST` or split into a distinct `MODEL_ARTIFACT_DIGEST`. The axes this
contract fixes answer the Phase 2A form of that question without a new class:

```text
relationship : declared        (§1, §2)
referent     : manifest | weight-bearing object   (§4 — named, not classed)
resolution   : direct | transitive                (§4)
execution    : not asserted    (§6)
```

The manifest-versus-weights question is a matter of **which object the author
named and how deeply a verifier resolved it**, not of two competing ontologies.
Recording the referent and the resolution depth carries the distinction, so
Phase 2A needs no taxonomy change.

Genuine residue, identified and not solved: A-04 was a question about a
**measurement** taxonomy — how a scorer should classify a digest it finds.
Phase 2A is a contribution, not a measurement, so that question is not live
here; it would become live again only if a later phase measured declared
bindings. The A-04 historical record in `AUDIT-DISPOSITION.md`,
`REPOSITORY.md` and the changelogs stays exactly as written.

## 12. Open questions reserved for syntax/design

Not resolved here, and deliberately not invented:

1. **Declaration cardinality — OPEN FOR SYNTAX/DESIGN.** The contract does not
   assume exactly one declared artifact. `Number of declared references` and
   `number of effective artifacts` are independent: Scope A can coherently
   declare **one** artifact while downstream execution uses **many**,
   and the Mesh result does **not** imply Scope A needs a set-valued
   declaration. Whether an author may declare several artifacts (for example a
   manifest plus a tokenizer, or a deliberately multi-model configuration) is
   not settled by the completed evidence.
2. **Declared configuration vs transmitted request (§2a).** Whether these
   warrant separate terms, given that they demonstrably diverge under shared
   compute.
3. **Digest-algorithm agility.** The contract says "under the stated digest
   semantics" without fixing an algorithm or how it is stated.
4. **Referent typing.** Whether the representation must distinguish a manifest
   referent from a weight-bearing-object referent, or whether a verifier
   discovers this on resolution (§4).
5. **Scope-declaration mechanics.** §8 requires that an unaware consumer not
   over-read the reference. How that is achieved structurally is syntax.
6. **Encoding.** Tag versus event, name, and whether any existing construct is
   profiled — expressly not decided (census dispositions are inputs, not
   conclusions).
