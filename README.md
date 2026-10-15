# Model-Artifact Binding — Phase 2A

An agent publishes a signed Nostr event that declares **which model artifact it
is talking about**, by content digest. Buzz carries the declaration unchanged.
Anyone holding the bytes can verify the declaration independently — and the
design is careful never to claim more than that.

```
Agent
  │
  │ signed Nostr event
  │ ["declared-model-artifact", SHA256(artifact bytes)]
  ▼
Buzz Relay
  │
  ├── NIP-42 auth
  ├── ingest
  ├── persistence
  └── historical REQ
  │
  ▼
Retrieved signed event
  │
  ▼
Reference Verifier
  │
  ├── signature                 PASS
  ├── declaration               VALID
  └── artifact digest           MATCH
       │
       ├── declared model artifact   ESTABLISHED
       ├── effective model      NOT ESTABLISHED
       └── execution            NOT ESTABLISHED
```

## Try it

```bash
./demo/run-demo.sh            # replay the preserved proof — needs only Python 3
./demo/run-demo.sh --live     # run the full round trip through a local Buzz relay
```

The live run needs a Buzz checkout, the dockerised Postgres, and the fixture
signing key, which is deliberately **not** in this repository.

## The problem

"This output came from Llama-3-8B" is unverifiable as usually stated. The model
name is a label, the weights are a moving target, and nothing in the message
ties the claim to any particular bytes. Worse, claims about *which model ran*
cannot be established by a message the model's own operator signs.

So this profile does one small, checkable thing instead. The author commits to a
**content identity** for an artifact, in a form anyone can recompute:

```
["declared-model-artifact", "<64 lowercase hex characters>"]
```

Two elements. The carrier name, and the SHA-256 of the artifact's literal bytes.
No algorithm field, no model name, no URL, no version, no referent type. The
digest is over the bytes exactly as they are — no canonicalisation, no
normalisation, no decompression.

## What was demonstrated

A real signed event carrying that tag made the complete trip through a live Buzz
relay at commit `4cd82f513214aad11c2b742ce7cc7c681e8e32a0`:

- NIP-42 authentication succeeded for the author key. No registration,
  membership or ownership record was created or fabricated.
- The relay ingested the event.
- **Persistence was proven by querying the database for the exact event id**,
  not inferred from an `OK` response.
- Historical authenticated `REQ` returned exactly that event.
- All seven semantic fields matched, and the relationship tag came back as
  exactly two elements carrying the exact submitted digest.
- The **event retrieved from the relay** — not the pre-submit object — passed the
  reference verifier against the artifact bytes.
- Flipping one byte of the artifact turned the digest result from `MATCH` to
  `NO MATCH` while the signature and the declaration stayed valid.

Full evidence, including the relay log extract and its extraction rule, is in
[`e2e/E2E-RESULT.md`](e2e/E2E-RESULT.md).

## What this does not claim

This is the part that matters most, and the verifier enforces it structurally:
there is no field in its output in which any of these could be reported.

| | |
|---|---|
| declared artifact identity | **established** by digest correspondence |
| author signed the declaration | **established** by the event signature |
| effective model selection | **not established** |
| model loading | **not established** |
| serving or inference participation | **not established** |
| execution | **not established** |
| execution attestation | **not established** |

```
DECLARED  ≠  EFFECTIVE  ≠  EXECUTED
```

A declaration records what an author asserted about an artifact's identity. A
valid signature proves the author signed it. Digest equality proves these bytes
are the artifact named. None of that proves what was loaded or run — and a
profile that quietly implied otherwise would be worse than useless.

## Where this fits with Mesh LLM

Three different things get verified at three different layers. Only the middle
one is what this repository demonstrates.

| Layer | What it verifies | Status here |
|---|---|---|
| **Mesh packaging** | Distributed software: release archives, native packages, container images, and their provenance. Its README describes requiring a verified SHA-256 for each selected host OS and architecture, checksum sidecars, an aggregate `SHA256SUMS`, SPDX SBOMs, provenance records, and base images resolved to immutable digests | Existing work, not ours |
| **Buzz Phase 2A** — this repository | The exact model-artifact bytes declared in a signed Nostr event, by SHA-256 over the literal bytes | **Demonstrated** end to end through a live Buzz relay |
| **Mesh LLM runtime** | Which model was actually selected, loaded, and used for a given inference | **Not demonstrated in this repository; runtime capabilities require confirmation with Mesh LLM maintainers.** |

The layers are complementary, and conflating them is the easy mistake. Knowing
that you installed a verified `mesh-llm` build tells you nothing about which
weights answered a particular request. Distribution digests stop at the engine;
this profile starts at the artifact a message refers to. Neither one reaches
execution.

### A possible chain, with the parts that exist marked

```
model artifact declaration     ← demonstrated: the tag, frozen and specified
        ↓
Buzz signed event              ← demonstrated: ingest, persistence, retrieval,
        ↓                         independent verification of the event the
        ↓                         relay returned
────────────────────────────── everything below this line is proposed, not built
        ↓
Mesh model selection           ← would require an authoritative selection record
        ↓
runtime model loading          ← would require the runtime to report the digest
        ↓                         of what it actually loaded
inference execution            ← would require linking a result to that evidence
        ↓
independently verifiable evidence
```

Above the line is running code with committed evidence. Below the line is a
sketch of what would have to exist, and none of it is claimed, implemented, or
promised by anybody. The profile is deliberately silent about all of it: the
verifier has no field in which model selection, loading or execution could be
reported, and that is structural rather than a gap awaiting a release.

### Three questions for Mesh LLM

These are questions, not requirements.

1. **Where does Mesh LLM resolve the effective model or model weights?** The
   declaration names bytes; something, somewhere, decides which bytes a request
   actually uses.
2. **Can the runtime expose the exact artifact digest of the model it loaded?**
   If it can, the same SHA-256 over literal bytes that this profile already
   specifies would compare directly against a declaration, with no new format.
3. **Can an inference result be associated with signed evidence identifying the
   participating model artifact?** This is the step that would connect a
   declaration to an execution, and whether anything provides it today is one of
   the things these questions are asking.

Any answer is useful, including that a capability is not exposed or not planned.
Confirming the current state with Mesh LLM maintainers is a precondition for
discussing whether these layers should connect at all, and nothing in this
repository depends on the answer.

## Repository map

| Path | What it is |
|---|---|
| `MODEL-ARTIFACT-BINDING-PROFILE.md` | the normative profile. The only authority here |
| `CONFORMANCE-VECTOR-SCHEMA.md` | reference-test corpus specification — format, case set, invariants |
| `CONFORMANCE-VECTOR-DESIGN-RECORD.md` | non-normative: rationale, retired cases, review findings |
| `CONFORMANCE-VECTORS.json` | 35 vectors — 1 positive, 26 negative, 8 verification |
| `verifier/mab_verify.py` | reference verifier. Standard library only, no dependencies |
| `e2e/` | the live-relay proof, with evidence and reproduction scripts |
| `demo/` | one-command demo and the presentation narrative |
| `PHASE2A-*.md` | the design gates that produced the profile |

```bash
python3 verifier/mab_verify.py --corpus CONFORMANCE-VECTORS.json   # 35/35
```

## Status, stated honestly

**Reference-test grade, not certification grade.** The corpus is sufficient to
show that a given implementation conforms on these vectors. It is not yet
sufficient to certify arbitrary third-party implementations: Section 11 of the
specification lists seven open items, each about how a foreign implementation is
invoked and judged rather than about what any vector contains.

**Kind-9 stream-message carriage is untested, not failed.** The proof ran on
Buzz's admitted global event path. The channel-scoped agent-message path needs a
channel and a membership record, which no supported local script provisions — so
nothing was fabricated to get around it. Nothing observed suggests the tag would
cause trouble there.

Which makes it a question for Buzz rather than homework:

> We proved the declaration end-to-end through Buzz's admitted global event path
> without modifying the relay. For the channel-scoped agent-message path, what is
> the supported local provisioning flow for an agent and a channel, so we can run
> the identical test without fabricating membership state?

## Provenance

Every artifact here is covered by a signed commit. The profile carries a
signed erratum (`80f5a1b8`) that removed a published regex whose `$` admitted a
trailing newline in several engines — the prose rule it duplicated is now stated
once.

Eight rounds of independent cold review preceded the freeze, each reviewer given
the profile, the schema and the pinned dependencies, and none given prior
findings or an expected outcome. Section 9 of the design record carries every
verified finding and its disposition — including the two positive cases retired
rather than left resting on a normative dependency the profile does not admit,
and the two cases found to be provably inert and corrected.
