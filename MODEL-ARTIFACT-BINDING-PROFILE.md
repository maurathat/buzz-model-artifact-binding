# Model-Artifact Binding Profile

Status: Phase 2A normative profile.

## 1. Scope

This profile defines one relationship: an author-declared model-artifact
relationship carried as a tag on a signed Nostr event [NIP-01].

```text
DECLARED ≠ EFFECTIVE ≠ EXECUTED
```

The relationship MUST NOT be interpreted as establishing downstream effective
selection, loading, serving, inference participation, execution, or execution
attestation.

## 2. Carrier

A relationship instance is the tag:

```text
["declared-model-artifact", "<digest>"]
```

A valid relationship instance MUST contain exactly two elements. The first
element MUST be exactly `declared-model-artifact`. The second element MUST
satisfy Section 5. No third or trailing element is permitted.

This profile does not specify how many `declared-model-artifact` tags an event
may carry.

## 3. Relationship semantics

The event author declares the artifact identified by `<digest>` as a model
artifact associated with the author's declared model configuration.

The declaration records an assertion by the event author. A valid event
signature establishes that the author signed the declaration; it does not
independently establish that the asserted relationship is true.

## 4. Artifact identity and digest

`<digest>` identifies the complete literal byte sequence of the declared
artifact. The digest algorithm is SHA-256 [FIPS180-4]. The digest preimage is
the artifact bytes only.

The digest operation MUST NOT perform parsing, semantic normalization,
reserialization, decompression, canonicalization, registry resolution, location
resolution, framing, prefixing, or referent-specific transformation. No UOR,
JCS, NFC or other canonicalization profile participates in computing the
digest.

A manifest is hashed as its literal serialized bytes. A weight-bearing artifact
is hashed as its literal bytes. The relationship carries no referent-type field.

## 5. Digest lexical form

The decoded string value of the second tag element MUST be, as a whole,
exactly 64 characters, each one of the ASCII characters `0`–`9` or
`a`–`f` (U+0030–U+0039, U+0061–U+0066). Uppercase letters, prefixes,
separators and whitespace are not permitted. No trimming, aliasing or
normalization is applied.

The following MUST NOT be accepted as valid: uppercase hexadecimal; a `sha256:`
or `sha-256:` prefix; a `0x` prefix; a base64, base64url or multibase encoding
of the digest; any string whose length is not 64.

The tag carries no algorithm information. SHA-256 is fixed by this profile.

## 6. Invalid relationship instances

A tag that violates the exact arity, the carrier spelling, the digest length,
the digest alphabet, the lowercase requirement, the no-prefix requirement or the
no-whitespace requirement is not a valid declaration under this profile.

A consumer applying this profile MUST NOT repair, trim, normalize or
reinterpret an invalid instance into a valid declaration.

This profile does not declare the containing Nostr event invalid when such a tag
is present, and does not require relay rejection.

## 7. Verification

1. A valid event signature establishes that the event author signed the
   declaration.
2. A verifier holding candidate artifact bytes recomputes SHA-256 over their
   complete literal byte sequence.
3. The verifier compares the resulting 32-byte digest with the value represented
   by `<digest>`.
4. Equality establishes that the candidate bytes correspond to the declared
   content digest.
5. Inequality establishes that those candidate bytes are not the artifact
   identified by that declaration.
6. Neither signature verification nor digest equality independently establishes
   that the asserted relationship between those bytes and the author's declared
   model configuration is true.

Verification MUST NOT require registry lookup, a naming authority, an artifact
location, or a retrieval service. Verification does not establish execution.

```text
identity ≠ retrievability ≠ availability ≠ provenance ≠ execution
```

## 8. Manifest and transitive resolution

A declaration whose digest identifies a manifest directly identifies the
manifest's literal bytes. If that verified manifest cryptographically
identifies weight-bearing objects, a verifier MAY separately establish
transitive relationships by resolving and verifying those objects. The
declaration does not thereby directly identify those downstream bytes.

## 9. Indexing

Relay indexing is not part of this profile. `declared-model-artifact` is a
multi-character carrier and does not intentionally invoke the NIP-01
single-letter tag-indexing convention. This profile does not prohibit a relay,
database, client or downstream service from independently indexing the tag.

## 10. Unspecified by this profile

This profile does not specify:

* event-level declaration cardinality;
* edit inheritance or redeclaration semantics;
* artifact retrieval or discovery;
* model-name extension syntax;
* referent-type extension syntax;
* retrieval-hint syntax;
* a future digest-algorithm migration or versioning mechanism;
* effective-artifact provenance;
* peer-served provenance;
* execution provenance;
* execution attestation.

## Normative references

* [NIP-01] Nostr NIP-01, *Basic protocol flow description*, at
  `nostr-protocol/nips` commit `a2494f4f81d46684e5814a9bf35e2b1df978f955`
  (2026-09-09): the event, its `tags` array, JSON string values, the event
  signature, and the single-letter tag-indexing convention. That revision is the
  normative baseline for this profile. Later revisions of NIP-01 do not change
  the meaning of this version of this profile.
* [FIPS180-4] NIST FIPS PUB 180-4, *Secure Hash Standard (SHS)*, August 2015:
  the SHA-256 function.
