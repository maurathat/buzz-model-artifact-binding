# Reference-Test Corpus Specification — Phase 2A

Normative definition of the vector format and case set for the Model-Artifact
Binding Profile. This document is what an implementer needs in order to generate
the corpus and to test an implementation against it.

**Grade: reference-test, not certification.** This specification is sufficient to
state that *a given implementation conforms to the frozen Phase 2A profile on
these vectors*. It is **not** yet sufficient to certify arbitrary third-party
implementations: Section 11 lists the open items that must be settled first, each
of which concerns how a foreign implementation is invoked and judged rather than
what any vector contains. No claim of certification capability should be made
against this revision.

Rationale, history, counterfactual analysis, the repairability study, retired
cases, the erratum record and review findings are in
`CONFORMANCE-VECTOR-DESIGN-RECORD.md`, which is non-normative. **Nothing in this
document requires that record in order to determine a result.**

Revision 10. Extracted from the Revision 8 combined record, whose content
SHA-256 is `774d138e84eb5bed31a6f4699dc76e9acb218c8946df4e0ad072959690ebd4fc`.

**Citation convention.** `profile §N` means a section of the normative profile
named in Section 1; its line numbers refer to the blob named there. `Section N`
means a section of this document.

## 1. Normative parent

```text
commit            80f5a1b8437563d265c1308fe1b74a84b8e357e4
path              MODEL-ARTIFACT-BINDING-PROFILE.md
content sha256    4de926b95fb4eb3791b861a671c652b7270d83e491502ec21145a9d62c5117c0
git blob id       d26fc8c7f206a6610afef4c4ca3c97f9f1b89c01
```

The content SHA-256 is the digest of the file's bytes; the git blob id is a
different value computed over a prefixed object. Both are given so that neither
is mistaken for the other. That commit is a signed erratum superseding the
earlier freeze `ec9e6003af1ec3efe205d554124d477b5250a78a`.

The profile is the sole normative source for this design. Where this document and
the profile disagree, the profile governs. This document does not amend,
reinterpret or extend the profile.

**Scope of this document's rules.** Section 5's rules govern this corpus and the
harness that runs it. They are not profile obligations: an application may expose
any additional outputs it likes and remain fully conforming to the profile.

## 2. Dependency boundary

Four classes, because they carry different authority.

| Class | Sources | Meaning |
|---|---|---|
| **Profile-admitted** | NIP-01 at pinned revision `a2494f4f81d46684e5814a9bf35e2b1df978f955` (profile §Normative references, lines 139-144); FIPS 180-4 (lines 145-146) | normative for profile conclusions |
| **Schema / container** | RFC 4648 §4 - padded standard-alphabet base64 for `candidate_b64` and `audit.digest_preimage_b64`. A JSON grammar (RFC 8259 or ECMA-404) - needed to parse `tag_json` and `event_json` at all, and to decide DNV-11 well-formedness | machinery this corpus cannot be read without. Not part of artifact identity, relationship semantics or the profile |
| **Fixture description** | RFC 4648 §5 (base64url, named at profile §5 line 66) — required to construct NV-E2 and to state the NV-E1/NV-E2 distinctness condition; multibase (named at profile §5 line 66, no specification admitted); gzip; Unicode normalization NFC/NFD/NFKC (profile §4 names NFC when excluding it); confusable relations | vocabulary for describing fixtures. Every verdict that mentions them is over-determined by character count, alphabet membership or byte inequality, so none is load-bearing |
| **Unadmitted for profile conclusions** | the JSON **escape-equivalence mapping** - which source spelling denotes which string value | **no case's expected result may depend on it.** See DNV-14, DNV-15 and the fixture spelling rule in Section 3 |

The last two rows carry the distinction that matters: a JSON grammar is container
machinery this corpus cannot do without, and that does **not** make escape
equivalence a rule of the profile.

## 3. Vector format

```jsonc
{
  "vector_schema": "mab-conformance-vector/1",
  "profile": { "commit": "80f5a1b8437563d265c1308fe1b74a84b8e357e4",
               "content_sha256": "4de926b95fb4eb3791b861a671c652b7270d83e491502ec21145a9d62c5117c0" },
  "id": "<opaque; unique; never reused; no path or position semantics>",
  "profile_refs": ["<profile section>"],
  "description": "<non-normative>",
  "input": {
    "tag_json":   "<literal JSON text of one tag array>",            // TAG shape
    "event_json": "<literal JSON text of a NIP-01 signed event>",    // EVENT shape
    "candidate_b64": "<standard base64, padded, of candidate bytes>" // required iff EVENT
  },
  "expected": {
    "relationship_instance_valid": true,
    "signature_valid": true,                 // EVENT only
    "established": {                         // EVENT only; closed vocabulary
      "author_signed_valid_declaration":    true,
      "candidate_matches_declared_digest":  true,
      "candidate_is_not_declared_artifact": false
    }
  },
  "audit": { "digest_preimage_b64": "<optional>" }
}
```

`vector_schema`, `profile`, `id`, `profile_refs`, `input` and `expected` are
mandatory. `description` and `audit` are optional and non-normative. Exactly one
of `tag_json` or `event_json` is present; `candidate_b64` is present if and only
if `event_json` is. `vector_schema` versions **this schema**, not the profile.

Candidate bytes are inline. There is no path, URL, registry or location field, so
a vector is verifiable from its own contents. `audit.digest_preimage_b64` lets a
reader confirm that a declared digest was computed over the bytes claimed; it is
**never supplied to a verifier**.

**Container encoding.** `candidate_b64` and `audit.digest_preimage_b64` use RFC
4648 §4 - standard alphabet, padding required. base64url MUST NOT be used. The
bytes a verifier hashes are the decoded bytes.

**Selection rule.** A tag is selected as a `declared-model-artifact` relationship
instance only when its carrier string value equals exactly
`declared-model-artifact`. Any other carrier value is not selected. This rule is
a property of the schema, never of the implementation under test. This document
does not define how a raw JSON source spelling becomes that string value - that
is DNV-14 - and the rule operates on the string value that the fixture
spelling rule below guarantees coincides with the fixture's source text.

**Designation, and the two harness operations.** Selecting an instance and
judging a designated candidate are different operations.

* **EVENT**: the subject is the one tag the selection rule identifies, which I2
  guarantees exists and is unique.
* **TAG**: the vector's single tag is the subject **by designation**.

A designated TAG subject that the selection rule would *not* select is still
judged, and its expected `relationship_instance_valid` is **`false`** - not
absent and not unanswerable - because profile §6 lines 73-75 make a tag
violating the carrier spelling "not a valid declaration under this profile".
That is how the carrier cases NV-C1, NV-C2, NV-C3 and NV-C4 exist as cases without
being selected as instances.

**Invocation contract.** A harness MUST present each TAG vector's designated
subject to a tag-level validity predicate and record the answer as
`relationship_instance_valid`. An implementation that declines to judge a tag
its own matcher would not select is recorded as reporting `false` for that
vector; "not selected" is not a third outcome. Without this rule an
implementation whose only entry point scans an event and returns the
declarations it finds would be testable under one harness and untestable under
another.

**Fixture hygiene (finite).** An EVENT fixture MUST NOT contain an unrelated tag
whose carrier value would collide with the subject under case folding, leading or
trailing whitespace trimming, affix tolerance or removal, normalization,
slugification or separator normalization, or confusable folding. The list is
deliberately finite so that a fixture author can discharge it, and conservative:
it includes classes this corpus does not vectorize, because excluding such a tag
from a fixture costs nothing.

**Fixture spelling rule.** The carrier and digest source spellings of every
active fixture MUST be chosen so that source text and intended string value
coincide without relying on the escape mapping - in practice, written with
literal unescaped characters. NV-H6 and NV-W3 are the two exceptions, noted in
their case definitions. **No vector's expected result may depend on resolving
DNV-14 or DNV-15.** This rule governs the relationship tag elements under test
only; it does not restrict JSON escaping elsewhere in an event, such as the
`content` field. It is fixture discipline for this corpus, not a profile rule.

**Single-defect rule.** Except where a case states otherwise, every component of
a fixture that is not that case's named defect MUST satisfy the valid baseline:
the carrier is exactly `declared-model-artifact` unless the carrier is the
defect; the digest is a 64-character lowercase-hex value unless the digest is the
defect; the arity is exactly two elements unless arity is the defect; any other
structural component is well-formed. Correcting only the named defect MUST yield
a valid relationship instance.

Where the digest **is** the defect, the baseline still governs the rest of it:
the fixture MUST be a valid 64-character lowercase-hex digest modified by exactly
the named defect and nothing more - one character replaced, the named material
added, the named length change, or the named re-encoding.

The rule exists for discriminating power. Without it,
`["declared-model-artifact", "ZZZ", ""]` would be an admissible arity negative
that an implementation ignoring arity entirely would still pass.

## 4. Output semantics

| Field | Semantics |
|---|---|
| `relationship_instance_valid` | Determinate judgement. `false` means the tag is not a valid relationship instance, which profile §6 line 75 licenses affirmatively |
| `signature_valid` | Determinate cryptographic result for EVENT vectors, per profile §7(1) and NIP-01's signature definition |
| `author_signed_valid_declaration` | Determinate, following from the two above by I4. `false` means there was no valid declaration to authenticate; it never claims the author failed to sign the tag that is present |
| `candidate_matches_declared_digest` | Establishment predicate. `false` means *this profile does not establish this conclusion for this vector* - never that the proposition is false, and never evidence for its negation |
| `candidate_is_not_declared_artifact` | Establishment predicate, same reading. **Not the Boolean negation of the key above:** when there is no valid declaration both are `false`, because neither conclusion can be established against a declaration that does not exist (I5). VF-8 is the case that discriminates this |

## 5. Conformance rules of this schema

* **S1 - closed output vocabulary.** The three `established` keys are the
  complete set of conclusions a vector can express; the profile defines a
  verification procedure for exactly these.
* **S2 - no other proposition is expressible.** This schema provides no field
  through which relationship truth, effective selection, loading, serving,
  inference participation, execution, execution attestation, retrievability,
  availability, provenance, transitive resolution, event validity, relay
  behavior or indexing can be reported as an established conclusion. Absence of
  such a field means the profile licenses no such conclusion; it never means the
  proposition is false.
* **S3 - comparison, and outputs outside the vocabulary.** **(a)** Comparison
  against `expected` is exact over the closed vocabulary. **(b)** An
  implementation that reports, as a conclusion of profile verification, any key
  outside that vocabulary is non-conforming **to this schema** for the purposes
  of this corpus. Clause (b) does not follow from clause (a): exact comparison
  over three keys would not by itself forbid a fourth. Both are harness rules,
  and neither claims that the profile forbids additional application-specific
  outputs.

## 6. Invariants

A vector violating any invariant is malformed.

* **I1** Exactly one shape: `tag_json` or `event_json`, never both and never
  neither. EVENT requires `candidate_b64`; TAG omits it.
* **I2** An EVENT fixture contains exactly one declaration tag as identified by
  the Section 3 selection rule, and that tag is the subject. Unrelated tags MAY
  coexist subject to fixture hygiene. This is a corpus property only and implies
  nothing about permitted cardinality, which the profile leaves unspecified.
* **I3** `expected` has no optional keys. TAG carries only
  `relationship_instance_valid`; EVENT carries all three top-level keys and all
  three `established` keys, always present, always boolean, never null. Key
  presence follows entirely from the shape. This invariant governs `expected`
  only.
* **I4** `author_signed_valid_declaration` = `signature_valid` AND
  `relationship_instance_valid`.
* **I5** `candidate_matches_declared_digest` requires a valid instance and digest
  equality. `candidate_is_not_declared_artifact` requires a valid instance and
  inequality. When the instance is invalid **both are false**: profile §6
  leaves no profile-valid declared digest for either conclusion to be
  established against. This preserves profile §7(4)/§7(5)'s asymmetry -
  equality yields correspondence to the declared content digest, inequality
  yields the stronger conclusion that the bytes are not the declared artifact.
* **I6** The `established` vocabulary is closed; adding a key requires a new
  `vector_schema` value.
* **I7** `id` is opaque, unique and never reused, and is not derived from a file
  name, path or corpus position. `profile_refs` entries are unique, are compared
  as a set, and have no ordering defined over them.
* **I8** No restriction on event kind, and no expected value may depend on it.
  The profile is silent on kind and this document introduces no kind taxonomy. A
  generator records whichever kind its fixtures use as non-normative
  scaffolding. Fixtures are single events, so no replacement or edit behavior is
  reachable whatever kind is used.

## 7. Requirements and observability

`discriminated` means at least one vector distinguishes a conforming
implementation from a violating one. `structural` means the schema affords no
field in which a violation could be reported. `not discriminated` means the
requirement is normative but the corpus cannot observe violations. `excluded`
means out of scope. The Limit column records an aspect that a discriminated
requirement does not reach.

| R | Requirement | profile § | Class | Cases or guards | Limit |
|---|---|---|---|---|---|
| R1 | Relationship is `["declared-model-artifact", "<digest>"]` carried on a signed NIP-01 event | §1, §2 | not discriminated | lexical parts via R2/R3/R5/R6 | the "on a signed event" clause is untested: TAG vectors carry no event and still expect a result |
| R2 | Exactly two elements; no third or trailing element | §2 (26-28) | discriminated | NV-A1, NV-A2, NV-A3 | - |
| R3 | First element exactly `declared-model-artifact` | §2 (26-27) | discriminated | NV-C1, NV-C2, NV-C3, NV-C4 | carrier matching **inside an event's `tags` array** is never exercised; the carrier cases are TAG shape, and I2 would make a wrong-carrier EVENT fixture malformed |
| R4 | Per-event declaration cardinality unspecified | §2 (30-31), §10 | excluded | DNV-1 | - |
| R5 | Decoded element two is, as a whole, exactly 64 characters from U+0030-U+0039 or U+0061-U+0066; no trimming, aliasing or normalization | §5 (59-63) | discriminated | PV-1; NV-H2 to NV-H6, NV-W1 to NV-W4 | - |
| R6 | The enumerated forbidden forms must not be accepted | §5 (65-67) | discriminated | NV-H1, NV-L1 to NV-L3, NV-P1 to NV-P3, NV-E1 to NV-E3 | - |
| R7 | A tag violating arity, carrier spelling, digest length, alphabet, lowercase, no-prefix or no-whitespace is not a valid declaration | §6 (73-75) | discriminated | all NV; VF-8 | - |
| R8 | No repair, trimming, normalization or reinterpretation | §5 (62-63), §6 (77-78) | discriminated | every NV case whose defect a transformation could undo; VF-8 | only repair that changes the **reported** result is reachable; internal repair followed by a correct report passes |
| R9 | An invalid instance does not invalidate the event and does not require relay rejection | §6 (80-81) | structural | DNV-2 | - |
| R10 | Digest is SHA-256 over the complete literal bytes; no transformation; no referent-type field | §4 | discriminated | VF-1, VF-3, VF-5, VF-6, VF-7 | two gaps. **"no referent-type field" is not discriminated** — DNV-6 declines to vectorize referent-type syntax and NV-A3 excludes extension-shaped elements, so no case observes it. And of the normalization directions, only **NFC-normalization-before-hashing** is observed: VF-6 fixes that direction, and an NFD-normalizing verifier passes the corpus |
| R11 | A manifest is hashed as its literal serialized bytes | §4 | discriminated | VF-3 | manifest-ness is not a verifier input, so VF-3 catches a reserializing verifier as an instance of R10; an implementation with no concept of manifests passes VF-3 and conforms |
| R12 | A valid signature establishes authorship, not the truth of the assertion | §3, §7(1) | not discriminated | - | DNV-10 keeps `signature_valid` constantly true, so I4 makes `author_signed_valid_declaration` an alias of instance validity; an implementation that never verifies a signature passes every vector |
| R13 | Equality and inequality conclusions, and their non-negation relationship | §7(2)-(5) | discriminated | VF-1, VF-2; VF-8 for the non-negation | - |
| R14 | Neither signature verification nor digest equality establishes the asserted relationship | §7(6) | structural | S1, S2 | - |
| R15 | Verification requires no registry, naming authority, location or retrieval service | §7 | not discriminated | DNV-5 | the format has no locator, so an implementation performing an invisible lookup passes everything; the corpus does not prove absence of network use |
| R16 | A manifest digest identifies the manifest bytes only; transitive resolution is optional | §8 | not discriminated | VF-4 is documentary; DNV-9 | distinguishing it requires the manifest-to-weights relationship as a verifier input, which the schema does not supply and must not fake |
| R17 | Relay indexing is outside this profile | §9 | excluded | DNV-3 | - |
| R18 | Everything listed in profile §10 is unspecified | §10 | excluded | DNV-1, DNV-4 to DNV-8 | - |
| R19 | MUST NOT be interpreted as establishing downstream effective selection, loading, serving, inference participation, execution or attestation | §1 (14-16) | structural | S2, DNV-8 | - |

R5 and R6 cite different sentences of profile §5: R5 is the lexical rule at
lines 59-63, R6 the enumeration at lines 65-67. A case is listed under R6 only
when the enumeration names its form.

## 8. Case definitions

**This section is the single source of truth for the case set.** Each case's
defect, fixture preconditions and discriminating target are stated here and
nowhere else. Active cases: **1 PV + 26 NV + 8 VF = 35**.

No fixture bytes are chosen here. These are preconditions a generator must
satisfy.

### 8.1 Positive - TAG shape

| Case | Definition and preconditions | Expected |
|---|---|---|
| PV-1 | Canonical tag: carrier exactly `declared-model-artifact`; digest a 64-character lowercase-hex value which MUST exercise all sixteen hexadecimal symbols | `relationship_instance_valid: true` |

### 8.2 Negative - TAG shape

Every NV case is TAG shape and expects `relationship_instance_valid: false`.
Each is subject to the single-defect rule in Section 3, so only the listed defect
departs from the valid baseline.

| Case | R | Sole defect | Fixture preconditions beyond the baseline | Discriminates |
|---|---|---|---|---|
| NV-A1 | R2 | one element: the digest element is absent | - | an implementation that reports `true`, or omits the judgement. An implementation with **no arity check at all** reads an absent element, applies the lexical rule and reaches `false` for the wrong reason, so it is not discriminated here; R2's discrimination rests on NV-A2 and NV-A3, which carry a valid carrier and a valid digest plus an extra element |
| NV-A2 | R2 | three elements, trailing empty string | - | an arity check that ignores an empty trailing element |
| NV-A3 | R2 | three elements, trailing non-empty | the third element is neutral, never shaped like a model-name, referent-type or retrieval-hint extension | destructuring `[name, value]` and ignoring index 2 and beyond |
| NV-C1 | R3 | carrier case variant | - | case-insensitive tag dispatch |
| NV-C2 | R3 | carrier with a trailing space | - | trimming tag names; prefix-only comparison |
| NV-C3 | R3 | carrier with an added **prefix** | the affix contains at least one non-whitespace character and MUST be a prefix, never a suffix; byte-distinct from NV-C2 and NV-C4. A suffix fixture would not catch an `endsWith` matcher, which a prefix does; the `startsWith` direction is caught by NV-C2 | unanchored carrier matching, or affix removal before comparison |
| NV-C4 | R3 | carrier with a leading space | byte-distinct from NV-C2, which carries a trailing space | an implementation that left-trims carrier names only, which NV-C2 does not catch |
| NV-H1 | R6 | every alphabetic digest character uppercase | the source digest contains at least two alphabetic characters and all are uppercased, so the fixture cannot coincide with NV-H2 | lowercasing before comparison |
| NV-H2 | R5 | exactly one alphabetic digest character uppercase | at least one other alphabetic character remains lowercase | case folding that a whole-string uppercase check would miss |
| NV-H3 | R5 | one non-hex ASCII character `g` | exactly 64 characters: one `g` and 63 valid lowercase hex characters | an alphabet written as `\w`, `[[:alnum:]]` or `[0-9a-z]` |
| NV-H4 | R5 | one compatibility-normalizable lookalike | the character is one that compatibility normalization maps **into** the alphabet, for example a fullwidth digit in the U+FF10 block; the other 63 characters are valid | an implementation that applies compatibility normalization before validating |
| NV-H5 | R5 | one non-normalizable confusable | the character is one that compatibility normalization does **not** map into the alphabet, for example a Cyrillic or Greek letter resembling a permitted one; the other 63 characters are valid | an implementation that applies confusable folding, or validates on appearance |
| NV-H6 | R5 | U+0000 followed by at least one further character, after a valid digest | requires an escape in `tag_json`; see the note below | C-string or FFI truncation at the first NUL |
| NV-L1 | R6 | 63 characters | all 63 are valid lowercase hex | a length quantifier written as a range or `+` |
| NV-L2 | R6 | 65 characters | all 65 are valid lowercase hex; the first character is not `f`, so the value is not a multibase base16 spelling; byte-distinct from NV-E3 | an unanchored or prefix-only length check that accepts the first 64 characters |
| NV-L3 | R6 | the empty string | - | a length check admitting the empty string, for example `{0,64}`, which reports `true`; also an implementation that omits the judgement. A truthiness test reaches the right answer for the wrong reason and is **not** discriminated |
| NV-P1 | R6 | `sha256:` prefix before a valid digest | - | prefix stripping |
| NV-P2 | R6 | `sha-256:` prefix before a valid digest | - | a stripper that handles only `sha256:` |
| NV-P3 | R6 | `0x` prefix before a valid digest | - | hex-literal parsing |
| NV-E1 | R6 | standard base64 spelling of the digest bytes | built from digest bytes whose RFC 4648 §4 and §5 encodings differ, which requires at least one 6-bit group mapping to alphabet index 62 or 63; without this NV-E1 and NV-E2 can be instantiated byte-identically | "try base64 decode, accept 32 bytes" |
| NV-E2 | R6 | base64url spelling of the same digest bytes | the same condition as NV-E1 | the same acceptance via a URL-safe decoder |
| NV-E3 | R6 | multibase base16 spelling: `f` followed by a valid digest | byte-distinct from NV-L2 | multiformats auto-detection |
| NV-W1 | R5 | a leading space before a valid digest | - | left trimming |
| NV-W2 | R5 | a trailing space after a valid digest | - | right trimming |
| NV-W3 | R5 | one line feed after a valid digest | requires an escape in `tag_json`; see the note below | an anchored-regex formulation whose `$` admits a terminal newline |
| NV-W4 | R5 | separators between byte pairs of a valid digest | the separator is not whitespace, so this case does not overlap the whitespace cases | stripping all non-hex characters before validation |

**Note on NV-H6 and NV-W3.** JSON forbids raw control characters inside a
string, so NV-H6's U+0000 and NV-W3's line feed cannot be written literally;
they are the two exceptions to the fixture spelling rule, written `\u0000` and
`\n`. **Their expected results hold under either reading of the escape
mapping:** read as decoded values, NV-H6 is 66 or more characters including one
outside the alphabet, and NV-W3 is 65 characters including whitespace; read as
literal source text, both contain a backslash - outside the alphabet - and both
exceed 64 characters. Invalid either way. Their **Discriminates** entries above
assume the decoded reading. Pinned NIP-01 does name a line-break escape at
`01.md:49` and names nothing for a NUL, but that provision is scoped to the
`content` field for producing the `id` serialization, not to tag element
spellings; it is corroboration only and no result rests on it.

**Note on NV-H4 and NV-H5.** These are not a clean partition of transformations:
compatibility normalization reaches NV-H4's character and leaves NV-H5's
untouched, while confusable folding may reach both. NV-H5 is the case that
catches a confusable-folding implementation and NV-H4 the one that catches a
normalizing implementation, and both are needed for that reason.

### 8.3 Verification - EVENT shape

Every VF fixture is a validly signed event. Each row states **all five**
expected keys explicitly, under these names: "instance" is
`relationship_instance_valid`, "signature" is `signature_valid`,
"signed-declaration" is `author_signed_valid_declaration`, "matches" is
`candidate_matches_declared_digest`, and "is-not" is
`candidate_is_not_declared_artifact`. No name abbreviates to something that
could denote a different key, and no expected value is left to be inferred from
prose.

| Case | R | Definition and preconditions | Expected | Discriminates |
|---|---|---|---|---|
| VF-1 | R10, R13 | Candidate equals the digest preimage; candidate content deliberately arbitrary; byte-distinct from VF-3's manifest | instance `true`, signature `true`, signed-declaration `true`, matches `true`, is-not `false` | any framing, prefixing or other transformation of the hashed bytes |
| VF-2 | R13 | Candidate differs from the preimage and MUST be unrelated to it - not a reserialization, normalization form or compression of it - so that VF-2 is byte-distinct from VF-4, VF-5, VF-6 and VF-7 | instance `true`, signature `true`, signed-declaration `true`, matches `false`, is-not `true` | an implementation that always reports a match |
| VF-3 | R10, R11 | Manifest bytes as both preimage and candidate. The manifest MUST be in a deliberately non-canonical literal serialization - non-sorted member order, irregular whitespace, or a form no common serializer emits - and byte-distinct from VF-1's candidate | instance `true`, signature `true`, signed-declaration `true`, matches `true`, is-not `false` | a verifier that normalizes or reserializes before hashing |
| VF-4 | R16 | Weight-bearing bytes that a manifest references, against that manifest's digest; byte-distinct from VF-2's candidate | instance `true`, signature `true`, signed-declaration `true`, matches `false`, is-not `true` | nothing - **documentary only.** Its expected result equals VF-2's, because the schema supplies no manifest and no locator, so no implementation can attempt transitive resolution. That the bytes are manifest-referenced is a fixture-author property, never a verifier input |
| VF-5 | R10 | **Declares the digest of a deterministic reserialization of VF-3's manifest as the preimage, and supplies the original deliberately non-canonical manifest bytes as the candidate.** The two byte sequences MUST differ. The direction is load-bearing: an honest verifier hashes the non-canonical candidate and gets a mismatch, while a verifier that reserializes the candidate before hashing reproduces the declared digest and reports a match. The opposite direction is inert, because reserializing an already-canonical candidate changes nothing | instance `true`, signature `true`, signed-declaration `true`, matches `false`, is-not `true` | a verifier that reserializes the candidate before hashing |
| VF-6 | R10 | **The declared preimage MUST be the NFC form and the candidate MUST be the corresponding NFD form of the same text.** The text MUST contain at least one character whose composed and decomposed forms differ, so the two byte sequences differ. The direction is fixed, not a choice: a verifier can only normalize the candidate it holds, so this direction catches an implementation that NFC-normalizes before hashing — it reproduces the declared digest and reports a match — while an honest verifier gets a mismatch | instance `true`, signature `true`, signed-declaration `true`, matches `false`, is-not `true` | a verifier that **NFC-normalizes the candidate** before hashing. An NFD-normalizing verifier is *not* caught by this case; testing that would require a separate case with the operands exchanged, which this corpus does not include (R10's Limit records it). Two *unrelated* sequences that merely each have distinct NFC and NFD forms would yield the same expected result while discriminating nothing, which is why the derivation is required |
| VF-7 | R10 | A deterministic literal preimage and a deterministic gzip encoding of it as candidate. Determinism requires pinning the modification time, the operating-system byte, the compression level, the absence of the FNAME, FEXTRA and FHCRC fields, and the deflate implementation, since implementations differ at the same nominal level; the candidate MUST differ from the preimage | instance `true`, signature `true`, signed-declaration `true`, matches `false`, is-not `true` | a verifier that decompresses before hashing |
| VF-8 | R7, R8, R13 | A validly signed event carrying an NV-H1-form instance, that is a digest whose alphabetic characters are uppercase. **The candidate bytes MUST hash to the lowercased digest value** - the value a wrongly repairing implementation would derive | instance `false`, signature `true`, signed-declaration `false`, matches `false`, is-not `false` | two things. **(1) No repair:** an implementation that lowercases the tag digest before comparing bytes reports matches `true` and fails, which the candidate condition is what makes observable. **(2) Non-negation:** an implementation computing is-not as the plain Boolean negation of matches reports is-not `true` and fails. VF-8 is the only case in which both establishment keys are `false`, so it is the sole discriminator of the I5 semantics |

## 9. Boundaries deliberately not vectorized

Assigning pass/fail expectations to these would make the corpus a second
specification. Each row's basis is either an item that profile §10 declares
unspecified, or a silence - a question the profile does not address anywhere, or
one the admitted dependency graph cannot answer.

| DNV | Behavior | Basis | Guard |
|---|---|---|---|
| DNV-1 | Zero, multiple or duplicate declarations per event | profile §2 (30-31) and a §10 item | I2: exactly one declaration under test, with no claim about permitted cardinality |
| DNV-2 | Event-level validity verdict; relay acceptance or rejection | profile §6 (80-81) | no such output exists |
| DNV-3 | Relay, database or client indexing | profile §9 | no such output exists |
| DNV-4 | Edits, redeclaration, replaceable-event semantics | profile §10 item | single-event fixtures only |
| DNV-5 | Retrieval, discovery, locations, registries | profile §7 and §10 items | no locator field; candidate bytes inline |
| DNV-6 | Model-name, referent-type and retrieval-hint extension syntax | profile §10 items | NV-A3's neutral third element |
| DNV-7 | Digest-algorithm migration or versioning | profile §10 item | length cases are plain character counts, never labelled as another algorithm |
| DNV-8 | Effective-artifact, peer-served and execution provenance; execution attestation | profile §1 and §10 items | no such output exists (S2, R19) |
| DNV-9 | Transitive resolution, which profile §8 leaves permissive | profile §8, a MAY | no case requires resolution, and no expected result depends on whether an implementation performs it |
| DNV-10 | Events with invalid signatures | silence: the profile states only what a *valid* signature establishes (§7(1)) | every VF fixture is validly signed; see R12's limit |
| DNV-11 | Inputs that are not well-formed NIP-01 tags: non-string elements, malformed JSON, arrays with no elements | NIP-01 well-formedness, which the profile delegates | not fixtures under this profile; profile conformance begins once the input is a well-formed NIP-01 tag |
| DNV-12 | Retired identifier, not reused | - | - |
| DNV-13 | Whether an unrelated tag in an event fixture carries meaning of its own | silence: the profile defines only this one tag. **Not a §10 item** | unrelated tags MAY appear subject to fixture hygiene. The only claim made is that such a tag is not an additional declaration under the selection rule; no claim of semantic inertness |
| DNV-14 | Whether an escaped **carrier** source spelling that decodes to the carrier is a valid instance | silence: profile §2 states the exact-string requirement, but no admitted source defines the source-text-to-string-value mapping. **Not a §10 item** | no case asserts either answer. The boundary does not change the rule applied once the carrier string value exists |
| DNV-15 | Whether an escaped **digest** source spelling that decodes to a valid digest is a valid instance | silence: profile §5 line 59 names the decoded string value, but no admitted source defines the mapping. **Not a §10 item** | no case asserts either answer. The boundary does not change profile §5's rule as applied to the digest string value |

## 10. Not decided by this document

* No fixture bytes, event, key or signature. Section 8 states preconditions, not
  values.
* The corpus-generation procedure, including the fixture event kind and the
  fixture signing key.
* The conformance runner, beyond three requirements: S3(a)'s comparison
  semantics; S3(b), which obliges the runner to enumerate the conclusion keys an
  implementation reports and to reject any key outside the closed vocabulary,
  since exact comparison over three keys would not by itself detect a fourth;
  and the rule that `audit.digest_preimage_b64` is never supplied to a verifier.
* Whether the profile should admit a JSON grammar as a normative reference, and
  therefore whether DNV-14's and DNV-15's boundaries could become positive cases.
* No profile text is amended, and no profile §10 item acquires an expectation.

## 11. Open certification items

These are recorded findings, not waived ones. Each was verified by independent
review of this specification. None changes any vector's contents or expected
result, which is why the corpus can be generated and a reference implementation
tested against it now; each must be settled before this specification is used to
**certify a third-party implementation**, because each is a way two honest
testers could judge the same foreign implementation differently.

| # | Open item | Why it blocks certification but not reference testing |
|---|---|---|
| C-1 | TAG-shape invocation for an implementation that exposes only an event-level entry point. Section 3's decline-to-judge rule covers a tag the implementation's own matcher would not select, which is the carrier cases; it does not say how PV-1 is driven against an event-only implementation, and §10 leaves the fixture event kind and signing key unfixed, so a synthetic wrapper is itself undefined | our reference verifier exposes a tag-level predicate, so the ambiguity does not arise for it. For a foreign implementation PV-1's verdict can invert between testers |
| C-2 | What counts as "a conclusion of profile verification" under S3(b). An implementation returning diagnostic fields alongside the three keys is diagnostics to one tester and non-conforming to another. A syntactic criterion is needed, for example that only keys inside the `established` object count | our reference verifier emits exactly the closed vocabulary |
| C-3 | `profile_refs` derivation and comparison. The field is mandatory but no rule derives it from a case's requirement row, and nothing states what it is compared against | it is never compared against an implementation, so no verdict depends on it |
| C-4 | The container grammar versus the escape boundary. Section 2 admits a JSON grammar as container machinery while listing the escape-equivalence mapping as unadmitted, and RFC 8259 §7 is where that mapping lives. The boundary should be restated where it actually bites: the **profile** does not normatively cite a JSON grammar, so escape equivalence cannot ground a profile conclusion | the fixture spelling rule keeps source text and string value coincident, and NV-H6's and NV-W3's results hold under either reading, so no result depends on it |
| C-5 | The U+0000 boundary. NV-H6 assumes a NUL-bearing tag element is a well-formed NIP-01 tag, while DNV-11 delegates well-formedness and NIP-01's "non-null strings" invites the other reading. Membership of NV-H6 in the case set, though not its expected result, turns on this | the expected result is `false` under either reading |
| C-6 | Abort, timeout and error mapping. The invocation contract maps a refusal to answer to `false` but says nothing about a crash — and NV-H6's declared target is a NUL-truncating implementation whose realistic failure mode is a fault | our reference verifier is built not to abort; a foreign one may |
| C-7 | Auditability of the Discriminates column. The counterfactual reasoning that justifies each case's discriminating target lives in the non-normative companion, so a reviewer cannot audit the column from this document alone — which is how two inert cases survived into Revision 10 | a tester reproducing results does not need the justification; a certifier correcting a precondition does |
