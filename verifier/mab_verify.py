#!/usr/bin/env python3
"""Reference verifier for the Model-Artifact Binding Profile, Phase 2A.

Implements exactly what the profile licenses and nothing more:

  1. NIP-01 event id and signature verification (BIP-340, no dependencies).
  2. Exact carrier recognition: the first tag element must equal
     "declared-model-artifact".
  3. Exact two-element arity.
  4. Digest lexical validation: exactly 64 characters, each one of 0-9 or a-f.
  5. SHA-256 over the complete literal candidate bytes, with no transformation.
  6. Match / mismatch conclusions.
  7. A closed output vocabulary. The machine result can express authorship of a
     valid declaration, digest correspondence, and non-correspondence. It has no
     field for the effective model, for execution, or for anything else the
     profile declines to establish.

Normative parent: profile 4de926b95fb4eb3791b861a671c652b7270d83e491502ec21145a9d62c5117c0
Specification:    dd752441750a6e6f6f76000504b3dfe7a9d7218480438d911f57d38c4ff99868

Usage:
    mab_verify.py --corpus CONFORMANCE-VECTORS.json
    mab_verify.py --event event.json --candidate artifact.bin [--human]
"""

import argparse, base64, hashlib, json, sys

CARRIER = "declared-model-artifact"
HEX = frozenset("0123456789abcdef")

# --------------------------------------------------------------------------
# BIP-340 Schnorr verification over secp256k1. Verification only; no signing.
# --------------------------------------------------------------------------
P = 2**256 - 2**32 - 977
N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8


def _lift_x(x):
    if x >= P:
        return None
    y = pow((x * x * x + 7) % P, (P + 1) // 4, P)
    if (y * y) % P != (x * x * x + 7) % P:
        return None
    return (x, y if y % 2 == 0 else P - y)


def _add(p1, p2):
    if p1 is None:
        return p2
    if p2 is None:
        return p1
    if p1[0] == p2[0] and (p1[1] + p2[1]) % P == 0:
        return None
    if p1 == p2:
        lam = 3 * p1[0] * p1[0] * pow(2 * p1[1], P - 2, P) % P
    else:
        lam = (p2[1] - p1[1]) * pow(p2[0] - p1[0], P - 2, P) % P
    x = (lam * lam - p1[0] - p2[0]) % P
    return (x, (lam * (p1[0] - x) - p1[1]) % P)


def _mul(point, k):
    acc = None
    while k:
        if k & 1:
            acc = _add(acc, point)
        point = _add(point, point)
        k >>= 1
    return acc


def _tagged(tag, msg):
    h = hashlib.sha256(tag.encode()).digest()
    return hashlib.sha256(h + h + msg).digest()


def schnorr_verify(msg32, pubkey_hex, sig_hex):
    """BIP-340 verify. msg32 is the 32-byte message (the event id)."""
    if len(pubkey_hex) != 64 or len(sig_hex) != 128:
        return False
    try:
        point = _lift_x(int(pubkey_hex, 16))
        r = int(sig_hex[:64], 16)
        s = int(sig_hex[64:], 16)
    except ValueError:
        return False
    if point is None or r >= P or s >= N:
        return False
    e = int.from_bytes(
        _tagged("BIP0340/challenge",
                r.to_bytes(32, "big") + point[0].to_bytes(32, "big") + msg32),
        "big") % N
    rp = _add(_mul((GX, GY), s), _mul((point[0], P - point[1]), e))
    return rp is not None and rp[1] % 2 == 0 and rp[0] == r


# --------------------------------------------------------------------------
# Profile rules
# --------------------------------------------------------------------------
def digest_lexically_valid(value):
    """Profile section 5: exactly 64 characters, each 0-9 or a-f.

    Deliberately not a regex: an anchored regex's `$` admits a trailing newline
    in several engines, which the profile's erratum exists to exclude.
    """
    return (isinstance(value, str) and len(value) == 64
            and all(c in HEX for c in value))


def relationship_instance_valid(tag):
    """Profile sections 2, 5 and 6. No repair, trimming or normalization."""
    return (isinstance(tag, list) and len(tag) == 2
            and tag[0] == CARRIER and digest_lexically_valid(tag[1]))


def nip01_event_id(event):
    """NIP-01: sha256 over the UTF-8 serialization of the ordered fields."""
    ser = json.dumps(
        [0, event["pubkey"], event["created_at"], event["kind"],
         event["tags"], event["content"]],
        separators=(",", ":"), ensure_ascii=False)
    return hashlib.sha256(ser.encode()).hexdigest()


def event_signature_valid(event):
    for key in ("id", "pubkey", "sig", "created_at", "kind", "tags", "content"):
        if key not in event:
            return False
    if nip01_event_id(event) != event["id"]:
        return False
    try:
        msg = bytes.fromhex(event["id"])
    except ValueError:
        return False
    return schnorr_verify(msg, event["pubkey"], event["sig"])


def select_declaration_tag(event):
    """The subject is the tag whose first element is exactly the carrier."""
    found = [t for t in event.get("tags", [])
             if isinstance(t, list) and t and t[0] == CARRIER]
    return found[0] if len(found) == 1 else None


# --------------------------------------------------------------------------
# Results. The machine result carries the closed vocabulary and nothing else.
# --------------------------------------------------------------------------
def verify_tag(tag):
    return {"relationship_instance_valid": relationship_instance_valid(tag)}


def verify_event(event, candidate_bytes):
    sig_ok = event_signature_valid(event)
    tag = select_declaration_tag(event)
    instance_ok = relationship_instance_valid(tag) if tag is not None else False
    if instance_ok:
        equal = hashlib.sha256(candidate_bytes).hexdigest() == tag[1]
        matches, is_not = equal, not equal
    else:
        # No profile-valid declared digest exists, so neither conclusion can be
        # established against it. This is not a Boolean negation.
        matches, is_not = False, False
    return {
        "relationship_instance_valid": instance_ok,
        "signature_valid": sig_ok,
        "established": {
            "author_signed_valid_declaration": bool(sig_ok and instance_ok),
            "candidate_matches_declared_digest": matches,
            "candidate_is_not_declared_artifact": is_not,
        },
    }


# --------------------------------------------------------------------------
# Presentation layer. Separate from the machine result by construction: it
# consumes a result and returns text, and never feeds anything back.
# --------------------------------------------------------------------------
def human_report(result):
    est = result.get("established", {})
    lines = []
    if "signature_valid" in result:
        lines.append(_row("event signature",
                          "PASS" if result["signature_valid"] else "FAIL"))
    lines.append(_row("declaration",
                      "VALID" if result["relationship_instance_valid"] else "INVALID"))
    if est:
        if result["relationship_instance_valid"]:
            digest = "MATCH" if est["candidate_matches_declared_digest"] else "NO MATCH"
        else:
            digest = "NOT COMPARED"
        lines.append(_row("artifact digest", digest))
        lines.append("")
        lines.append(_row("author signed declaration",
                          "ESTABLISHED" if est["author_signed_valid_declaration"]
                          else "NOT ESTABLISHED"))
        lines.append(_row("declared model artifact",
                          "ESTABLISHED" if est["candidate_matches_declared_digest"]
                          else "NOT ESTABLISHED"))
        lines.append(_row("effective model", "NOT ESTABLISHED"))
        lines.append(_row("execution", "NOT ESTABLISHED"))
        lines.append("")
        lines.append("The last two are not failures. This profile cannot establish")
        lines.append("them, and no verifier output of ours ever will: a declaration")
        lines.append("records what the author asserted, not what was loaded or run.")
    return "\n".join(lines)


def _row(label, value):
    return f"{label:<34}{value}"


# --------------------------------------------------------------------------
def run_corpus(path):
    corpus = json.load(open(path))
    passed = failed = 0
    for vector in corpus["vectors"]:
        inp, expected = vector["input"], vector["expected"]
        if "tag_json" in inp:
            got = verify_tag(json.loads(inp["tag_json"]))
        else:
            got = verify_event(json.loads(inp["event_json"]),
                               base64.b64decode(inp["candidate_b64"]))
        if got == expected:
            passed += 1
        else:
            failed += 1
            print(f"FAIL {vector['id']}  {vector.get('description','')}")
            print(f"  expected {json.dumps(expected, sort_keys=True)}")
            print(f"  got      {json.dumps(got, sort_keys=True)}")
    total = passed + failed
    print(f"{passed}/{total} vectors pass" + ("" if failed else "  — all green"))
    return 0 if failed == 0 else 1


def main():
    ap = argparse.ArgumentParser(description="Model-Artifact Binding reference verifier")
    ap.add_argument("--corpus", help="run a vector corpus")
    ap.add_argument("--event", help="a NIP-01 signed event, as JSON")
    ap.add_argument("--candidate", help="candidate artifact bytes")
    ap.add_argument("--tag", help="a single tag array, as JSON text")
    ap.add_argument("--human", action="store_true", help="human-readable report")
    args = ap.parse_args()

    if args.corpus:
        return run_corpus(args.corpus)
    if args.tag:
        result = verify_tag(json.loads(args.tag))
    elif args.event and args.candidate:
        result = verify_event(json.load(open(args.event)),
                              open(args.candidate, "rb").read())
    else:
        ap.error("need --corpus, or --tag, or --event with --candidate")
    print(human_report(result) if args.human
          else json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
