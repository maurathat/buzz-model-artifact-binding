# Conformance-Vector Design Record

**Non-normative.** This record explains why `CONFORMANCE-VECTOR-SCHEMA.md` says
what it says. It is development provenance: methodology, evidence, rejected
alternatives, retired cases, revision history and review findings.

Nothing here is authority. The schema does not depend on this record to
determine any result, and where the two disagree the schema governs — as the
schema in turn defers to the normative profile.

Companion to the reference-test corpus specification whose content SHA-256 is
`dd752441750a6e6f6f76000504b3dfe7a9d7218480438d911f57d38c4ff99868`, bound to the
normative profile at commit `80f5a1b8437563d265c1308fe1b74a84b8e357e4`, content
SHA-256 `4de926b95fb4eb3791b861a671c652b7270d83e491502ec21145a9d62c5117c0`.

`profile §N` refers to the profile; `schema §N` to the schema document.

## 1. Method

Four rules governed the design, and each exists because an earlier revision
broke it.

1. **Derive boundaries from every published normative representation, not only
   from the intended rule.** A formalization can admit inputs the prose rejects,
   and a suite derived from the semantics alone will not find it. This rule comes
   from the regex defect in Section 6.
2. **"Covered" means discriminating.** Before a requirement is listed as
   discriminated, answer the counterfactual: can an implementation violate it and
   still produce every expected result in the corpus? If yes, it is not
   discriminated and must be classified honestly.
3. **Fixture-author knowledge is not a verifier input.** If a case's meaning
   depends on a fact the vector does not supply to the verifier, the case is
   documentary. VF-4 is the worked example.
4. **The corpus may not enlarge the profile's normative dependency graph.** A
   case may only enforce a conclusion derivable from the profile and the sources
   the profile admits. If a derivation needs another authority, the question
   becomes a boundary until that dependency is approved for the profile itself.
   The corpus is not a repair mechanism for an omission in the profile. PV-2 and
   PV-3 were retired under this rule.

## 2. Evidence: JSON escape spellings, and why two positive cases were retired

**Question.** Does a tag element whose JSON source uses an escape sequence, but
which decodes to the required string, satisfy the profile?

**Classification: requires a normative dependency the profile does not admit.**
The question is left open for both tag elements, as schema DNV-14 (carrier) and
DNV-15 (digest).

The derivation needs three steps and the third is unavailable:

| Step | Claim | Source | Status |
|---|---|---|---|
| 1 | The profile delegates the event, its `tags` array, JSON string values and the event signature to NIP-01 at the pinned revision | profile §Normative references, lines 139–144 | admitted |
| 2 | A tag is an array of strings, so tag elements are string-valued rather than source text | NIP-01 `01.md:24`, `01.md:40`, `01.md:59` | admitted |
| 3 | A JSON Unicode escape spelling and the character it represents denote the same string value — the source-text-to-string-value mapping | not in the profile and not in pinned NIP-01 | **NOT admitted** |

Pinned NIP-01 contains no `\uXXXX` rule and cites no JSON specification. Its only
escape provisions, `01.md:48-55`, list seven escapes — line break, double quote,
backslash, carriage return, tab, backspace, form feed — scoped to "the content
field" for the purpose of *producing* the `id` serialization. None of those seven
characters occurs in `declared-model-artifact`, and none is a member of `0`–`9`
or `a`–`f`, so no escaped spelling of either the carrier or a valid digest is
covered by any provision of pinned NIP-01. Reaching step 3 requires the JSON
grammar itself — RFC 8259 or ECMA-404 — which the profile does not admit.

**Literal characters are not at issue.** A character written literally has the
same sequence as source text and as string value, so no mapping rule is needed to
read it, and step 3 does not reach it. That is why PV-1 and the schema's fixture
spelling rule stand on admitted sources while PV-2 and PV-3 are retired. Step 3
is not the identity mapping. An earlier revision shipped an example of step 3
that had been silently decoded in transit, so that it read as the identity
mapping; that defect survived three revisions before a reviewer caught it, and
the schema now states the proposition in prose alongside the literal sequence.

**On the delegation.** Profile line 141 does name "JSON string values", which is
the very object step 3 concerns. The honest statement of the gap is therefore not
that the profile is silent, but that **it delegates the term to a source that
underdefines it**: pinned NIP-01 uses tag strings without defining how source
text becomes a string value. The retirements follow either way, because a
positive case needs a definition, not a delegation.

**A JSON grammar is still container machinery.** The vector format carries
`tag_json` and `event_json` as JSON text, and DNV-11 excludes malformed JSON, so
a parser is needed to read the corpus at all. The schema's dependency table
separates that mechanical need from escape equivalence as a profile rule; the
first is unavoidable, the second is unadmitted and no expected result may depend
on it.

**Evidence relied upon.** NIP-01 at `nostr-protocol/nips` revision
`a2494f4f81d46684e5814a9bf35e2b1df978f955`, commit date 2026-09-09, whose
`01.md` has content SHA-256
`6cd76682e7ec2d635f1f46b3660f621cdad1193d9174d316674b91f8d683af26`. The cited
lines were read at that revision. This record states no claim about which copies
of any source are present on any particular machine; such a claim is not
provenance of a derivation and decays.

## 3. Evidence: the §2/§5 asymmetry and profile §6's "carrier spelling"

Profile §5 names the decoded string value for element two. Profile §2 states an
exact string requirement for element one without naming one. Under Section 2
neither statement resolves how a source spelling becomes a string value, so the
schema takes no position for either element and vectorizes neither answer.

Profile §6 line 73 lists "the carrier spelling" among the violation axes. The
other axes in that sentence are of two kinds. The digest length, the digest
alphabet, the lowercase requirement, the no-prefix requirement and the
no-whitespace requirement are each properties of a string value under profile §5.
The exact arity is not a string-value property at all: it is a property of the
tag array. Reading "the carrier spelling" as a property of JSON source text would
place it in neither kind — not with the five string-value axes beside it, and not
with the one structural axis — whereas reading it as the spelling of the carrier
string value puts it with the five.

That reading is analysis only. It is not load-bearing for any case, because both
cases it would have supported are retired.

## 4. Counterfactual analysis behind the observability classes

The test is method rule 2. For each requirement the schema classifies, the
reasoning is:

**Discriminated.** R2, R3, R5, R6, R7, R8, R10, R11, R13. Each has at least one
vector that an implementation violating it fails — given the single-defect rule,
without which an unrelated defect could force the same expected `false` and leave
the requirement untested. R11's discrimination depends entirely on VF-3's
non-canonical-serialization precondition: without it a normalizing verifier would
pass VF-3 and the case would add nothing to VF-1.

**Structural.** R9, R14, R19. The schema affords no field in which a violation
could be reported — no event-validity or relay output for R9, no relationship
truth for R14, no downstream-use conclusion for R19 — so no vector can contradict
an implementation that violates them.

**Not discriminated, and why each resists a fix.**

* **R1** — the lexical parts are covered by R2/R3/R5/R6, but TAG vectors carry no
  event at all and still expect a result, so nothing penalizes an implementation
  indifferent to event context.
* **R12** — DNV-10 keeps invalid signatures out of the corpus, so
  `signature_valid` is constantly `true` and I4 makes
  `author_signed_valid_declaration` an alias of instance validity. An
  implementation that never verifies a signature passes every vector. No
  invalid-signature case was invented to rescue it, because the profile states
  only what a *valid* signature establishes.
* **R15** — the format has no locator, so no vector requires a lookup and an
  implementation performing an invisible external lookup passes everything. The
  corpus does not prove the absence of network or service use.
* **R16** — distinguishing "the manifest bytes only" from downstream identity
  requires the manifest-to-weights relationship as a verifier input, which the
  schema does not supply and must not fake. VF-4 is therefore documentary and
  observationally identical to VF-2.

**Clause-level limits inside discriminated requirements.** R3's carrier matching
is never exercised inside an event's `tags` array, because the carrier cases are
TAG shape and I2 would make a wrong-carrier EVENT fixture malformed: an
implementation strict on a designated tag but case-insensitive when scanning an
event passes the corpus. R8 reaches only repair that changes the *reported*
result; an implementation may repair internally and still report
`relationship_instance_valid: false`, and profile §6 lines 77–78 carry no
"before judging" qualifier, so that violation is unobservable here.

## 5. The repairability study

This analysis motivated the single-defect rule and several fixture conditions. It
is not itself a rule of the schema.

**Criterion.** A negative case is *repairable* when some transformation of the
malformed instance can produce **any** valid relationship instance — not
necessarily the one a fixture was derived from. Profile §6 lines 77–78 say "into
a valid declaration", not "into the intended one".

The transformation must operate on material already present. It may **map**
present characters to others under an externally recognized relation — case
mapping, Unicode compatibility normalization, confusable folding — **remove**
present characters or elements, or **re-encode** present material. A
transformation that *introduces* material the instance does not contain — padding
a short value to length, substituting an arbitrary permitted character for a
forbidden one, supplying a missing element, or emitting a fixed valid instance
regardless of input — is **fabrication, not repair**. Without that bound the
criterion is vacuous, since a transformation that discards its input and emits a
valid digest would make every case repairable.

Substituting a character for one it bears no recognized relation to is
fabrication even though both are "mappings": that is the difference between
NV-H5, whose character stands in a confusable relation to a permitted one, and
NV-H3, whose `g` stands in no recognized relation to any hexadecimal digit.
Operations may compose — NV-E1 and NV-E2 are repairable by decoding followed by
re-encoding, because their 32 bytes *are* the digest value under another
encoding — provided every step stays within the classes above. NV-L1's 63
characters encode no 32-byte value, which is why zero-padding them is fabrication
rather than re-encoding.

**Repairable, 22 cases:**

| Transformation an implementation might wrongly apply | Cases |
|---|---|
| dropping a trailing element | NV-A2, NV-A3 |
| case folding | NV-C1, NV-H1, NV-H2 |
| trimming | NV-C2, NV-C4, NV-W1, NV-W2, NV-W3 |
| affix removal | NV-C3 |
| prefix removal | NV-P1, NV-P2, NV-P3 |
| separator removal | NV-W4 |
| alternate-encoding decoding and re-encoding | NV-E1, NV-E2 |
| multibase prefix removal, or truncation to 64 characters | NV-E3 |
| compatibility normalization | NV-H4 |
| confusable folding | NV-H5 |
| truncation — at the NUL for NV-H6, to 64 characters for NV-L2 | NV-H6, NV-L2 |

**Not repairable without fabrication, 4 cases:**

| Case | Why |
|---|---|
| NV-A1 | No digest element is present; supplying one is fabrication |
| NV-H3 | The forbidden character is present but no recognized mapping carries it into the alphabet, and removing it leaves 63 characters. Its fixture is pinned at exactly 64 characters with one `g`, so this holds by construction |
| NV-L1 | 63 characters are present; reaching 64 requires introducing a character |
| NV-L3 | No characters are present, so any valid value would be fabricated entirely |

NV-H6's and NV-W3's entries assume the decoded reading of the escape mapping,
exactly as the schema's note on those two cases records.

**Repairability and single-defect isolation are distinct, and neither implies the
other.** Single-defect isolation is a property of the fixture: everything but the
named defect is valid. Repairability asks whether a transformation of present
material reaches a valid instance. A case can be single-defect and
non-repairable: NV-A1's absent digest element is its only defect, and correcting
it yields a valid instance, yet *supplying* it is fabrication rather than repair.
Negative cases are not required to be repairable.

## 6. Normative-parent history: the regex erratum

| | |
|---|---|
| Superseded | commit `ec9e6003af1ec3efe205d554124d477b5250a78a`; profile content SHA-256 `65382bd50c98f956f21cb51bbf15aae0b809108e934a184610d2aeb5b8d83b1f`; git blob id `e66347db5960d97a64fbf8f1922968f0ae01307f` |
| Current | commit `80f5a1b8437563d265c1308fe1b74a84b8e357e4`; profile content SHA-256 `4de926b95fb4eb3791b861a671c652b7270d83e491502ec21145a9d62c5117c0`; git blob id `d26fc8c7f206a6610afef4c4ca3c97f9f1b89c01` |
| Classification | TRANSCRIPTION/ERRATUM — no design decision changed |

The superseded profile's §5 carried two representations of one rule: prose
requiring a whole-value match of exactly 64 lowercase-hex characters, and the
regex `^[0-9a-f]{64}$`. The two are not equivalent across regex dialects, because
`$` may match before a final newline. Measured during review: a 64-character
digest followed by a line feed is **accepted** by Python, Perl and Ruby and
**rejected** by Node and Go, while `grep -E` accepts the line because it never
sees the newline. The erratum removed the regex and left the prose rule, so the
profile now states the rule once, without regex semantics.

`PHASE2A-REPRESENTATION-GATE-4A.md` remains unchanged in the repository. Its
"Equivalently, the whole value must match `^[0-9a-f]{64}$`, anchored at both
ends, with no multiline mode" is historical evidence of what was certified at
that checkpoint. The qualifier it offers does not cure the defect, since
`$`-before-final-newline is default rather than multiline behavior in the
affected engines. The antecedent gate's case table tested 63, 65 and "trailing
whitespace" but never a terminal newline specifically, which is why a suite
derived from the intended semantics could not have exposed it — the origin of
method rule 1.

NV-W3 is retained for this reason even though the profile no longer publishes a
regex: implementations may still use an anchored-regex formulation internally.

The provenance worksheet, `MODEL-ARTIFACT-BINDING-PROFILE-PROVENANCE.md`, is
non-normative, kept outside Git, and its grammar derivations cite the superseded
regex and are stale.

## 7. Retired identifiers

Never reused; later identifiers never renumbered.

| Identifier | Status |
|---|---|
| PV-2 | Retired in Revision 5. A digest written with escape sequences decoding to a valid digest. The profile names the decoded string value for element two, but no admitted source defines the source-text-to-string-value mapping, so the fixture is not constructible from admitted sources and no positive case may enforce it. The boundary is DNV-15 |
| PV-3 | Retired in Revision 4. An escaped carrier spelling decoding exactly to `declared-model-artifact`, introduced in Revision 2 as a positive case. Retired on the same ground as PV-2. The boundary is DNV-14 |
| NV-A4 | Retired in Revision 3. A zero-element tag `[]`, added in Revision 2 as an arity negative. NIP-01 requires a tag to be an array of one or more strings (`01.md:59`), so `[]` is malformed at the NIP-01 layer — the class DNV-11 excludes — and it is never reached by the profile's two-element rule |
| DNV-12 | Retired in Revision 2. The escaped-carrier boundary, now DNV-14, with the digest-element boundary as DNV-15. Not revived |

## 8. Revision history

No revision of the schema has ever been committed to the repository; each was an
untracked working-tree file when reviewed. Exact bytes for Revisions 2 through 8
are preserved outside Git in `../phase2a-review-lineage/`, with Revision 1
recorded there as bytes-unavailable and deliberately not reconstructed.

| Rev | SHA-256 | Cases | Review outcome |
|---|---|---|---|
| 1 | `54c83cef…b3ebd49f4f1` | 33 | FAIL. Bytes not preserved; transcript record only |
| 2 | `6f7ddeaa…60f46fa9` | 33 | FAIL on two independent reviews — overstated coverage for two requirements, a case outside its own scope boundary, an unguarded fixture collision, an undefined tag-selection rule |
| 3 | `00ddaf10…e55c45b` | 36 | PASS WITH CONDITIONS — six P2. First revision bound to the corrected parent |
| 4 | `c0be7f7d…3581e63c` | 35 | PASS WITH CONDITIONS — one P0, one P1, four P2 |
| 5 | `fc5ac299…0a92f03f` | 34 | PASS WITH CONDITIONS — one P0, one P1, four P2 |
| 6 | `af443a41…0bf879c6` | 34 | PASS WITH CONDITIONS — one P1, four P2 |
| 7 | `4d91243b…89287f564` | 34 | PASS WITH CONDITIONS — two P1, three P2 |
| 8 | `774d138e…690ebd4fc` | 34 | PASS WITH CONDITIONS — two P1, two P2, eight P3 |
| 9 | split into schema + this record | 34 | PASS WITH CONDITIONS — one P0 (an abbreviation key contradicting VF-8's expected set), five P1, seven P2 |
| 10 | schema `5abcc28f…6502d4b31` | 35 | PASS WITH CONDITIONS — four P1 (two cases provably inert or direction-ambiguous, two harness conventions undetermined), five P2 |
| 11 | schema `dd752441…4ff99868` | 35 | reference-test freeze; certification items recorded open in schema §11 |

Case counts moved only in response to findings, never for symmetry. Each
transition, aligned with the retirement table in Section 7:

* Rev 2 → Rev 3: 33 → 36. NV-A4 (zero-element tag) added, three further
  negatives added, one case split, and the arity negative later retired in the
  same revision's review cycle.
* Rev 3 → Rev 4: 36 → 35. NV-A4 retired to the NIP-01 layer (DNV-11) and PV-3
  retired, offset by added negatives.
* Rev 4 → Rev 5: 35 → 34. PV-2 retired.
* Rev 5 → Rev 9: 34 throughout. No case added or removed.
* Rev 9 → Rev 10: 34 → 35. NV-C4 added, closing a carrier leading-space hole
  that no case covered.

## 9. Review findings and their dispositions

Six independent cold reviews, each given the profile, the schema and the pinned
dependencies, and none given prior findings or an expected outcome. Verified
findings and what they produced:

| Round | Finding | Disposition |
|---|---|---|
| 1 | Two requirements' coverage overstated; one case outside the record's own scope boundary; a fixture-collision hazard unguarded; tag selection undefined | R12 and R16 demoted; the zero-element case retired to DNV-11; base64 distinctness condition added; the selection rule written |
| 2 | A positive case rested on an unadmitted dependency; the repairability criterion was unbounded | PV-3 retired to DNV-14; the criterion bounded |
| 3 | One case misclassified against the record's own criterion; two retained negatives depended on the escape mapping undisclosed | NV-H5 reclassified as repairable; the NV-H6/NV-W3 disclosure written |
| 4 | No fixture-spelling rule, so two retired cases could re-enter under live identifiers; profile §1's prohibition had no requirement identifier | the spelling rule added; R19 indexed |
| 5 | A write-time encoding artifact had collapsed an escape example into the identity mapping; no single-defect rule, leaving two coverage claims unsecured | the example restated and byte-verified; the single-defect rule added, plus its digest-baseline clause and NV-H3's pinned length |
| 6 | The dependency inventory understated the JSON grammar it mechanically relies on; the escape-dependency enumeration undercounted; VF-8 had no candidate condition and was an unrecorded sole discriminator | the four-class dependency table; the enumeration completed; VF-8's candidate condition and its non-negation role written into its case definition |

| 7 | The compact schema's abbreviation key contradicted VF-8's expected set; NV-C3's affix direction was a free choice that changed the verdict on an `endsWith` matcher; VF-6's precondition did not entail its claimed discrimination; NV-A1 did not discriminate R2; the harness invocation contract and S3(b)'s enforceability were undefined; a carrier leading-space hole | every VF row now states all five expected keys under unambiguous names; NV-C3 pinned to a prefix and NV-C4 added; VF-6 required to be an NFC/NFD derivation; NV-A1's claim corrected; the invocation contract written and S3(b) bound to the runner in the schema's own "not decided" list |

| 8 | VF-5 was provably inert — its operand direction meant a reserializing verifier produced the expected result; VF-6's "or the two exchanged" let two conforming corpora reach opposite verdicts on the same NFC-normalizing implementation; the carrier enumeration was stale; four further items concern how a foreign implementation is invoked and judged | VF-5's operands swapped; VF-6 pinned to NFC-normalization-before-hashing, with the uncovered NFD direction recorded in R10's Limit; enumeration fixed. The four remaining items are recorded as open certification items in schema §11 rather than waived, and the artifact is labelled reference-test grade |

Both inert cases survived because the counterfactual reasoning that would have
exposed them lives here rather than in the normative document — the auditability
gap now recorded as C-7. VF-5's defect was introduced by an earlier correction,
and VF-6's by adopting a prior reviewer's suggested wording verbatim without
working through the operand direction.

Round 6's findings are what triggered the split. Across all six rounds no review
found a defect in the architecture — the shapes, the selection and designation
machinery, S1–S3, I1–I8, the observability classes or the retirement policy.
The defects clustered instead in restatement drift, where one fact lived in
several prose sections and one copy went stale, and in per-case fixture
preconditions. The split removes the first class by giving each fact a single
home: the schema's case table is the only place a case's defect, preconditions
and discriminating target are stated.

## 10. Worksheet C1–C10 cross-check

Diagnostic only, against the non-normative provenance worksheet kept outside
Git. No case derives from it, and because the worksheet is outside the repository
this table is not checkable from the committed material alone.

| Worksheet case | Covered by | Note |
|---|---|---|
| C1 | PV-1 | |
| C2 | NV-H1 | |
| C3 | NV-L1 | |
| C4 | NV-W1 | |
| C5 | NV-P1 | |
| C6 | NV-A3 | |
| C7 | VF-3 | |
| C8 | VF-5 | The worksheet's result is conditional on the digests differing; VF-5's preconditions make the eventual vector's result unconditional |
| C9 | VF-1 | The worksheet premise "unrelated bytes" is not determinable under the profile and appears nowhere in a vector. Its stated result — that none of this establishes the relationship — is represented by the absence of any such field under S1 and S2, not by a false boolean |
| C10 | VF-3, VF-4 | VF-4 is documentary; the permissive part of profile §8 maps to DNV-9 and is not tested |

The map names 10 distinct cases — PV-1, NV-A3, NV-H1, NV-L1, NV-P1, NV-W1, VF-1,
VF-3, VF-4, VF-5 — so the complement is 35 − 10 = 25: NV-A1, NV-A2, NV-C1,
NV-C2, NV-C3, NV-C4, NV-E1, NV-E2, NV-E3, NV-H2, NV-H3, NV-H4, NV-H5, NV-H6,
NV-L2, NV-L3, NV-P2, NV-P3, NV-W2, NV-W3, NV-W4, VF-2, VF-6, VF-7, VF-8.

No worksheet case exposes a missing profile-derived case, and none asks for a
conclusion the profile does not license.

## 11. Alternatives considered and rejected

| Alternative | Why rejected |
|---|---|
| Admit RFC 8259 or ECMA-404 so the escaped-spelling positives could stay | Would enlarge the profile's normative dependency graph from the corpus, making the suite a repair mechanism for an omission in the profile. Retirement to DNV-14/DNV-15 keeps the question open for a future profile revision, which is where it belongs |
| Add an invalid-signature case to rescue R12 | The profile states only what a *valid* signature establishes, so an expected result for an invalid one would be invented. R12 is classified not-discriminated instead |
| Report a third value — "not established" — rather than `false` | An establishment predicate's `false` already means "not established"; a third value would invite reading the others as truth claims. The closed vocabulary plus S2 carries the boundary instead |
| Keep the worksheet's C1–C10 as the case set | The worksheet is non-normative and outside Git; using its labels as authority would quietly promote it. The cases are derived from the profile and the worksheet is a completeness cross-check only |
| A `relationship_truth: false` field to express the non-conclusion | Manufactures an output for a proposition the profile never evaluates. Absence of the field is the stronger statement |
| Retain a second positive case for balance | PV-1 exercises all sixteen hexadecimal symbols, which is the whole of the positive lexical surface. A second positive added for symmetry would have had to be an escaped spelling, which is exactly what is unavailable |

## 12. Open profile-level questions

These concern the profile, not the schema. None is decided here and no case
depends on an answer.

| # | Question |
|---|---|
| 1 | Where is the source-text-to-string-value mapping defined for tag elements? Neither the profile nor pinned NIP-01 states a `\uXXXX` escape rule, so neither an escaped carrier spelling nor an escaped digest spelling can be constructed or judged from admitted sources. This is why DNV-14 and DNV-15 are boundaries rather than cases |
| 2 | Would the profile benefit from admitting a JSON grammar — RFC 8259 or ECMA-404 — as a normative reference? Doing so would resolve question 1 and both boundaries together, and would let escaped-spelling positive cases be introduced under new identifiers. Phase 2A is conformant and useful without it |
| 3 | Profile §2 states the carrier requirement without naming a string-value boundary, while profile §5 line 59 names one for the digest. Section 3 reads that asymmetry as drafting emphasis rather than a substantive difference — a reading, not a finding — and the profile could settle it by stating the boundary once for both elements |
