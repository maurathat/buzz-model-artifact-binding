# Three minutes, one visual

The whole talk hangs on one picture and one byte. Everything else is support.

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
       ├── declared artifact    ESTABLISHED
       ├── effective model      NOT ESTABLISHED
       └── execution            NOT ESTABLISHED
```

Have the visual up before you start talking, and leave it up the whole time.
Every beat below points at a part of it.

---

## 0:00 — 0:30 · The problem

> When an agent says "this came from Llama-3-8B," nothing in that message is
> checkable. The model name is a label. Nobody can recompute it.
>
> So we stopped trying to say which model ran, and made the one claim that *is*
> checkable: the content identity of an artifact.

One line on screen, and it is the entire wire format:

```
["declared-model-artifact", "eff10530…"]
```

> Two elements. A carrier name and a SHA-256 over the artifact's literal bytes.
> No algorithm field, no model name, no URL, no version. Nothing to negotiate,
> nothing to get wrong.

**Do not** explain the profile's internals here. The audience needs the tag
shape and nothing else.

## 0:30 — 1:15 · It works on Buzz today

Point at the middle of the visual.

> This ran against Buzz at commit `4cd82f51`, unmodified. NIP-42 auth, ingest,
> persistence, historical REQ.
>
> Two things we were strict about. Persistence was proven by querying the
> database for the exact event id — not by trusting an `OK`. And the event we
> hand to the verifier is the one the relay gave *back*, not the object we
> submitted. All seven semantic fields came back identical, and the tag came
> back as exactly two elements carrying the exact digest.

```bash
./demo/run-demo.sh
```

Let it print. Do not talk over the verifier panel — let them read
`signature PASS / declaration VALID / artifact digest MATCH`.

## 1:15 — 2:00 · The one byte

This is the moment. Slow down.

> The artifact is 61 bytes. I'm going to change one of them — same length, one
> bit — and run the identical verification again.

The output flips to `artifact digest NO MATCH`, with the signature and the
declaration still valid. Let that sit for a second before explaining it.

> The signature is still good. The declaration is still well-formed. The author
> really did sign it, and flipping a byte of the artifact can't forge that or
> break it.
>
> What changed is the only thing that *should* change: whether these particular
> bytes are the artifact the declaration identifies.

If one sentence survives the meeting, it is that one.

## 2:00 — 2:40 · What it never claims

Point at the bottom three lines of the visual.

> Two of those say NOT ESTABLISHED, and they will say NOT ESTABLISHED forever.
> That isn't a gap we're planning to close — the verifier has no field in which
> it could report otherwise. That's structural, not editorial.

```
DECLARED  ≠  EFFECTIVE  ≠  EXECUTED
```

> A declaration records what an author asserted about an artifact's identity. A
> signature proves they asserted it. A digest match proves these bytes are the
> artifact named. None of it proves what was selected, loaded, served or run,
> and a profile that implied otherwise would be worse than having no profile.

That boundary is the contribution. The digest is the easy part.

## 2:40 — 3:00 · The ask

> Reference-test grade, not certification grade — seven open items, all about
> how a *foreign* implementation gets invoked and judged, not about what any
> vector contains. They're written down, not waived.
>
> One thing I couldn't test, and I didn't want to fake it:

> **We proved the declaration end-to-end through Buzz's admitted global event
> path without modifying the relay. For the channel-scoped agent-message path,
> what is the supported local provisioning flow for an agent and a channel, so
> we can run the identical test without fabricating membership state?**

Then stop talking.

---

## If asked

**"Why not sign the model itself?"** — You can't. The operator controls the
signing key and the loader; a signature over a weights file says nothing about
what the server actually loaded. This profile declines that claim on purpose
instead of pretending to cover it.

**"Why no algorithm identifier?"** — Every optional field is a divergence point
between implementations. SHA-256, 64 lowercase hex, exactly two elements. If it
ever needs to change, that is a new carrier name, not a new field.

**"What if the digest is malformed?"** — Then *both* establishment conclusions
are false. Not the negation of each other — there is no profile-valid declared
digest to compare against, so neither conclusion can be established. The corpus
pins that as invariant I5.

**"Did you change the relay?"** — No. Buzz checkout clean at `4cd82f51`. No
rows inserted, no membership manufactured, no auth bypassed.

**"Is kind 9 broken?"** — Untested, not failed. Nothing observed suggests the
tag causes trouble there; the blocker was provisioning, which is the question
above.

**"How big is the verifier?"** — 261 lines, standard library only, including its
own BIP-340 verification. The corpus is 35 vectors: 1 positive, 26 negative,
8 verification.

```bash
python3 verifier/mab_verify.py --corpus CONFORMANCE-VECTORS.json
```

## Rehearsal notes

* Run `./demo/run-demo.sh` once before the room fills. Replay mode needs only
  Python 3 — no relay, no Docker, no key. Use it if the network is unreliable.
* `--live` needs the Buzz checkout, the isolated Postgres on 3002/3013/3014, and
  the fixture key outside the repo. Have replay mode as the fallback, and say
  out loud which mode you are in.
* Terminal at a readable size before you start. The verifier panel is the
  payload; if the back row can't read `MATCH` → `NO MATCH`, the talk doesn't land.
