#!/usr/bin/env bash
# Deterministic extraction rule for the committed relay evidence.
#
# The raw relay logs are ~340 KB each and dominated by unrelated startup noise,
# so they are not committed. This filter is the complete rule by which
# relay-evidence.log was produced: a holder of the raw logs can reproduce the
# committed extract byte for byte by running
#
#   relay-log-filter.sh <raw-submit.log> <raw-retrieve.log>
#
# It selects only the four relay messages that carry the proof: NIP-42
# authentication, the two ingest confirmations, and historical REQ delivery.
# No line is hand-selected and no line is edited.
set -euo pipefail
grep -hE '"message":"(NIP-42 auth successful|Event ingested via pipeline|Event ingested|EOSE sent after historical delivery)"' "$@"
