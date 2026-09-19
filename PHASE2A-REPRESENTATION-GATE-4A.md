# Buzz Phase 2A — Representation Gate 4A: Digest Profile

**Status at writing: review draft, prepared outside Git.** Defines the digest
profile and lexical validity rules for the family Gate 3 selected. It does not
name the carrier (that is Gate 4B), implements nothing, builds no test vectors
and opens nothing upstream. Placeholder used throughout: `<carrier>`.

## 1. Committed basis

`buzz-model-artifact-binding` HEAD `0f94208e96e128d7903826f98c995adbebbafec2`:

| File | sha256 (committed blob) |
|---|---|
| `PHASE2A-SEMANTIC-CONTRACT.md` | `94fc88e53759d83083ee679c8189f6b54c3d08cc19d6caa1f557945d5ab7cbc5` |
| `PHASE2A-REPRESENTATION-GATE-1.md` | `6177d39cc9b96a59f1184132d3bc7fc4d7cfeb06f696c48868e6544dd5a2568d` |
| `PHASE2A-REPRESENTATION-GATE-2.md` | `0c2b1dce38aa1e70c368eb79e6c9d14dffd3e3a0d003eaf6a54ef9a8853c5dba` |
| `PHASE2A-REPRESENTATION-GATE-3.md` | `bc124fd17a915f8ad0272491692fd42372385253558fb598f4fe89810de330c2` |

**Frozen family (Gate 3):** a predicate-specific carrier plus a digest. There
are exactly two serialized elements, the carrier identifier and the digest
value. The carrier definition fixes the Scope A predicate, the
declared-not-effective-not-executed scope and the digest algorithm. The signed
event supplies the declarant. Gate 4A adds no element.

**External sources read on 2026-09-18:** NIP-01 and NIP-94 at nips master;
Blossom BUD-00/01/02; NIST FIPS 180-4 (August 2015); NIST SP 800-107 Rev. 1
Table 1; the BLAKE3 specification (BLAKE3-team/BLAKE3-specs, `blake3.pdf`),
README and C2SP entry; the noble-hashes and
nostr-tools sources; rust-nostr. Buzz behaviour is taken from the pinned commit
`4cd82f51`.

## 2. Byte-preimage decision

**Rule tested:** *the digest is computed over the exact byte sequence of the
declared artifact, with no semantic normalization, parsing, reserialization,
decompression, canonicalization or registry resolution performed by the Phase 2A
digest operation.*

**It follows from the committed record; it is not adopted on suggestion:**

* Contract §3: a digest "identifies BYTES", and "any party holding candidate
  bytes can decide match/no-match unaided". Any normalization step would make
  the decision depend on a normalization procedure as well as the bytes.
* Contract §3: no registry lookup, no naming authority; the comparison is "a
  local computation over bytes the verifier already holds". Registry resolution
  and location play no part.
* Contract §4: "a manifest digest directly binds only the manifest". The
  object bound is the manifest as held, not a semantic reading of it.
* Gate 2: referent type is MAY, so the verifier may not know the artifact's
  class. Any normalization would be format-specific and would therefore require
  referent typing. A literal-bytes rule is the only rule that works without it.

**Precision needed for two implementers to agree.** The preimage is the
artifact's complete byte sequence as a single octet string. No framing, header,
length prefix or type tag is added before hashing — unlike, for example, git's
object hashing, which prepends a header. The digest of an artifact is
`SHA-256(bytes)` and nothing else (§3).

| Case | Preimage | Why |
|---|---|---|
| Ordinary weight-bearing file | the file's bytes as held | contract §3 |
| Manifest | the manifest's literal serialized bytes — **not** a normalized semantic form | contract §4; normalizing would need a format-specific canonical form, which contract §3 does not provide |
| Compressed, archive or container artifact | the bytes of the declared artifact **as presented** (for example the archive file), not its decoded contents | decoding would add container semantics the contract does not define. Declaring decoded contents means declaring *those* bytes |
| Remote object | the same bytes, however obtained; the location never enters the preimage | contract §5: identity ≠ retrievability ≠ availability |

**One rule works for every referent type.** No referent-specific hashing
semantics are needed, so there is no contradiction.

## 3. Algorithm comparison and selection

A bounded comparison, per the brief:

| Criterion | SHA-256 | SHA-512/256 | BLAKE3-256 |
|---|---|---|---|
| Collision resistance | 128-bit (SP 800-107r1 Table 1; whether that publication is still current was not checked) | 128-bit (same table) | 128-bit security target for its security goals, per the BLAKE3 specification (`blake3.pdf`; checked at review) |
| Fixed output | 256 bits (FIPS 180-4 Fig. 1) | 256 bits (FIPS 180-4 Fig. 1, §6.7) | 256 bits by default (BLAKE3 README) |
| Local computation over exact bytes | yes | yes | yes |
| Standardization | NIST FIPS 180-4 | NIST FIPS 180-4 | not NIST (not in FIPS 180-4); not IETF — the only draft, `draft-aumasson-blake3`, expired 2025-01-23; specified by the community C2SP project |
| Presence in Nostr implementations | **already required**: NIP-01 defines the event `id` as the sha256 of the serialization (01.md:19,32), so every NIP-01-conforming implementation that creates or verifies event ids requires it. rust-nostr uses `bitcoin_hashes::sha256` for ids; nostr-tools uses `@noble/hashes` | available in `@noble/hashes` (`sha512_256`); **not required** by any NIP for event handling. Availability in rust-nostr's hash crate: UNDETERMINED | available in `@noble/hashes` (`blake3`); **not required** by any NIP. At the Buzz pin it is used only for pseudonymous actor labels in conformance tooling (`buzz-conformance/src/lib.rs:108`), not for content addressing |
| Consistency with Nostr/Blossom content addressing | matches: Blossom addresses blobs by sha256 of the exact bytes (BUD-00:21, BUD-02:42), and NIP-94 `x` is SHA-256 (94.md:17). At the Buzz pin the relay validates a media `x` as 64-char lowercase hex SHA-256 (imeta.rs:88, Gate 1) | none | none |
| Interoperability burden | none added | adds a second hash primitive | adds a second primitive, and a non-FIPS one |
| Registry/service dependency | none | none | none |
| Migration under Gate 3 | per §11 | same | same |

**Selected: SHA-256.** The deciding reason is not familiarity; it is the
interoperability criterion. Every NIP-01-conforming implementation that creates
or verifies event ids already requires SHA-256, because NIP-01 defines event ids
with it. Choosing it adds no primitive to any such implementation. It also gives the
same identifier as Blossom and NIP-94 for the same bytes. That is identity
agreement only: no Blossom or NIP-94 semantics are imported (Gate 1).

**Why the others were not needed.**
* **SHA-512/256** also yields a 256-bit digest with the same collision
  strength, and it satisfies no Gate 2 requirement that SHA-256 does not. It
  would add a second primitive where SHA-256 is already required by NIP-01 and
  already used for Nostr/Blossom content addressing.
* **BLAKE3** offers speed and a tree mode. Speed is not a selection criterion
  under this brief. It adds a dependency no NIP requires and is not a NIST or
  IETF standard. Neither advantage answers a committed requirement.

## 4. Textual encoding decision

**Selected: lowercase hexadecimal, exactly 64 characters.**

| Option | Outcome |
|---|---|
| **lowercase hex** | Matches NIP-01's convention for 32-byte values: `id` and `pubkey` are "lowercase hex-encoded" (01.md:19–20), and `#e`/`#p` filter values MUST be exactly 64-character lowercase hex (01.md:141). Matches Buzz's own validation of a SHA-256 value, "64-char lowercase hex" (imeta.rs:88, Gate 1). Blossom's only normative statement of hash text is lowercase hex (BUD-02:44). One representation per digest |
| uppercase hex | Contrary to the NIP-01 convention. Accepting it as well would create a case alias |
| base64 / base64url | Not the Nostr convention for 32-byte values. Standard and URL-safe alphabets differ, and padding may or may not be present — several strings for one value |
| multibase | Its prefix identifies the encoding, and with multihash the algorithm. Both are already fixed by the carrier definition (Gate 3); a prefix would reintroduce a per-instance degree of freedom Gate 3 removed |

Human transcription and debugging favour hex. Its entire alphabet is plain
ASCII, which NIP-01's serialization never escapes, so a valid digest string
round-trips through Nostr JSON unchanged.

## 5. Exact lexical grammar

The grammar applies to the **string value** of the tag element, after ordinary
JSON string decoding:

```text
digest  = 64 HEXLC
HEXLC   = %x30-39 / %x61-66        ; "0"-"9" and "a"-"f" only
```

Equivalently, the whole value must match `^[0-9a-f]{64}$`, anchored at both
ends, with no multiline mode.

* Exactly 64 characters; the empty string is invalid.
* Only the 16 ASCII code points above. Any other character is invalid,
  including uppercase `A`–`F` and any non-ASCII character or visual confusable.
* Whitespace anywhere, including leading or trailing, is invalid. **Nothing is
  trimmed.**
* Prefixes such as `sha256:`, `sha-256:` or `0x` are invalid.
* Separators such as `:`, `-`, space or `_` are invalid.

**Tag arity:** a relationship instance is a tag of **exactly two** elements,
`[<carrier>, <digest>]`.
* One element (missing digest): **invalid**.
* Three or more elements: **invalid**. Trailing elements are not ignored.

Why trailing elements are rejected rather than ignored. No committed requirement
authorizes a third element. An ignored trailing slot is an undeclared extension
point that different implementations can come to read differently, and Gate 1's
central finding was that open positional slots attract owners (Gate 3 §5). Gate 3
routed evolution through new or versioned representation definitions, not
per-instance additions. EXTENSION items from Gate 2 (model name, retrieval
hints) are therefore **not** carried as trailing elements of this carrier;
where they would go is left to a later definition. The cost, stated: this
carrier cannot be extended in place.

**What INVALID means.** An invalid instance is **not** a Scope A declaration,
and a conforming consumer MUST NOT treat it as one or repair it into one. The
profile governs the relationship instance only. It does not decide whether the
carrying event is acceptable to a relay; the event remains an ordinary Nostr
event under NIP-01.

## 6. Invalid-input table

| Input | Disposition |
|---|---|
| valid 64-char lowercase hex, exactly two elements | **VALID** |
| missing digest (one-element tag) | INVALID |
| empty digest `""` | INVALID |
| wrong length (63, 65 or any length ≠ 64) | INVALID |
| invalid character (for example `g`, `z`) | INVALID |
| uppercase form (any of `A`–`F`) | INVALID |
| leading whitespace | INVALID |
| trailing whitespace | INVALID |
| algorithm prefix (`sha256:…`, `sha-256:…`) | INVALID |
| `0x` prefix | INVALID |
| embedded separator (`:`, `-`, space) | INVALID |
| extra tag element (three or more) | INVALID |
| too few tag elements | INVALID (the same case as a missing digest) |
| Unicode confusable (for example fullwidth `ａ`, Cyrillic `а`) | INVALID |

There are no WARNING, NORMALIZE, BEST-EFFORT or INDETERMINATE outcomes. No
committed requirement calls for one.

## 7. Canonicality

**Can two distinct valid strings represent the same digest value? No.**
Lowercase hex over a fixed 32-byte value is a bijection: every digest has
exactly one valid spelling, and every valid spelling decodes to exactly one
digest. There are no aliases.

This is canonical *digest text* only. Canonical *event serialization* is
NIP-01's concern and is not redefined here. Because the digest alphabet contains
nothing NIP-01 escapes, a valid digest string survives event serialization
unchanged.

## 8. Semantic-falsehood boundary

Lexical validity is not truth. A tag can be lexically valid, and candidate bytes
can match its digest, while the author's assertion is still false — the bytes
are not in fact a model artifact associated with the author's declared model
configuration. That is not a lexical failure, and this profile cannot detect it.
Validation under Gate 4A establishes only that the instance is well formed.
Together with the signature and a digest check, it establishes at most the
contract's §5(1)–(3), and never the truth of the relationship (contract §2 and
§5; Gate 3 §4).

## 9. Manifest / direct–transitive compatibility

The profile is identical for weight-bearing bytes and for manifest bytes. It
does not know, and cannot tell, which it is. A declared manifest's digest
identifies the manifest's literal bytes; a verifier may then inspect the
manifest and establish transitive relationships under contract §4, recording its
own resolution depth. No referent type and no depth are added.

## 10. UOR / canonicalization boundary

**Phase 2A requires no UOR, JCS, NFC, semantic canonicalization or other
external canonicalization profile to compute the declared artifact digest.** The
preimage is literal bytes (§2). The only canonical form Gate 4A defines is the
64-character text of the digest itself.

The consequence, stated plainly: **two semantically equivalent but
byte-different artifacts have different Phase 2A content identities**, unless
some artifact format independently defines those bytes to be identical or
canonical. A JSON manifest re-serialized with its keys in a different order is a
different artifact under this profile. That is the intended behaviour of a byte
identity, not a defect of it.

## 11. Migration boundary

The algorithm is fixed by the representation definition (Gate 3), and this
profile fixes it as SHA-256. If SHA-256 must ever be replaced:
* declarations under this representation keep their SHA-256 meaning;
* migration requires a new or versioned representation definition;
* Gate 4A does not decide how that versioning is encoded, and adds no version
  field;
* existing declarations never silently change their algorithm interpretation.

## 12. Normative profile table

| Property | Gate 4A decision |
|---|---|
| Digest preimage | the declared artifact's complete, literal byte sequence, with no framing, prefix or normalization |
| Fixed algorithm | SHA-256 (FIPS 180-4) |
| Output bits/bytes | 256 bits / 32 bytes |
| Text encoding | lowercase hexadecimal |
| Text length | exactly 64 characters |
| Allowed characters | `0`–`9`, `a`–`f` (U+0030–U+0039, U+0061–U+0066) |
| Case | lowercase only; uppercase INVALID |
| Prefix | none permitted; any prefix INVALID |
| Whitespace | none permitted; not trimmed; INVALID |
| Tag arity | exactly 2: `[<carrier>, <digest>]` |
| Extra elements | INVALID (not ignored) |
| Normalization | none, of either the digest text or the preimage |
| Missing/malformed digest | INVALID; the instance is not a Scope A declaration |
| Referent-specific behavior | none |
| External lookup required | none |
| Canonicalization dependency | none (no UOR, JCS, NFC or other profile) |

## 13. Test-vector sketch (categories only)

**Positive**
* lexical boundaries: an all-`0` and an all-`f` digest (lexically valid);
* the digest of a small known byte sequence (the empty sequence, and FIPS
  180-4's published example inputs, as independent references);
* manifest bytes, and weight-bearing or file bytes, under the identical rule;
* a *pair* of semantically equivalent but byte-different manifests producing
  **different** digests, pinning §10.

**Negative:** at least one case for every INVALID class in §6.

No fixtures and no verifier are built here.

## 14. Cheap falsification

**Widenings tried — each rejected because no committed requirement asks for
it:**

| Widening | Requirement that would force it | Outcome |
|---|---|---|
| accept uppercase | none; it would create a case alias | rejected |
| trim whitespace | none; it would create whitespace aliases and a normalization step | rejected |
| accept an algorithm prefix | none; the algorithm is fixed by the carrier (Gate 3) | rejected |
| accept or ignore trailing elements | none; it would open an unowned positional slot (Gate 1, Gate 3 §5) | rejected |
| accept several textual encodings | none; it would create aliases | rejected |
| hash a normalized manifest | none; it contradicts contract §3/§4 and would require referent typing (Gate 2: MAY) | rejected |

**Rules removed tried — each kept because two implementations could then
disagree:**
* Drop the lowercase rule: one accepts `A`, another rejects it. **Kept.**
* Drop no-trimming: one trims, another does not. **Kept.**
* Drop exact arity: one ignores extra elements, another rejects them. **Kept.**
* Drop the no-framing preimage rule: one hashes raw bytes, another adds a
  git-style header. **Kept.**
* Drop the fixed length: truncated digests become ambiguous. **Kept.**

## 15. Contradiction gate

* **Contradicts the semantic contract?** No. Literal-byte identity follows from
  §3, §4 and §5; the non-claims in §6 are untouched.
* **Contradicts Gate 1?** No. SHA-256 hex is the same *text shape* as `x` and
  Blossom values; no tag and no semantics are reused.
* **Contradicts Gate 2?** No. The algorithm is known from the carrier
  definition, not inferred from the value's shape (Gate 2 constraint 5).
* **Contradicts Gate 3?** No. Two elements, one per-instance degree of freedom,
  algorithm fixed by the definition.
* **Requires another serialized field?** No.
* **Requires referent-specific digest semantics?** No (§2, §9).
* **Introduces UOR or canonicalization?** No (§10).
* **Requires changing Candidate 1?** No.

## 16. Gate 4B remainder

Left open: the public carrier/tag name; single-letter vs multi-character vs
namespaced; relay-indexing implications; collision analysis for candidate
names; the final naming rationale.

**Constraints this profile places on naming — recorded, not decided:**
* The digest value is lexically identical to a NIP-01 event id or pubkey and to
  `x` or Blossom SHA-256 text (all 64 lowercase hex). The value alone therefore
  cannot distinguish the relationship; the **carrier name must**, and it must
  not be a tag whose existing meaning already takes a 64-hex value.
* Single-letter tags are, by NIP-01 convention, "expected to be indexed by
  relays", and "only the first value in any given tag is indexed" (01.md:84). A
  single-letter carrier would make the digest queryable through `#<letter>`
  filters. Whether that is wanted is a Gate 4B decision.
