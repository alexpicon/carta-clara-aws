#!/usr/bin/env bash
#
# vendor_prompts.sh — Carta Clara pre-build vendoring step (KODA-11)
#
# SAM packages each Lambda from its own CodeUri (src/scan/, src/ask/,
# src/refusal_log/, src/scan_packet/). Files outside a function's CodeUri are
# NOT in its deployment artifact. Two things therefore have to be copied INTO
# each handler directory before `sam build`:
#
#   1. helpers.py   — canonical source: src/_shared/helpers.py
#   2. prompts/*.md — authored by Sage in backend/prompts/
#
# This script does both. It is idempotent: running it twice is safe and
# produces the same result. Run it before EVERY `sam build` / `sam deploy`
# (or just use `make build`, which calls it for you).
#
# If backend/prompts/ has no .md files yet (Sage hasn't delivered), the script
# warns and exits 0 — handlers fall back to their built-in prompts so a build
# still succeeds.
#
# Usage:  ./scripts/vendor_prompts.sh        (from backend/, or anywhere)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$BACKEND_DIR/src"
PROMPTS_DIR="$BACKEND_DIR/prompts"

HANDLERS=(scan ask refusal_log scan_packet)
CANONICAL_HELPERS="$SRC_DIR/_shared/helpers.py"

echo "vendor_prompts: backend=$BACKEND_DIR"

# --- 1. re-vendor helpers.py -------------------------------------------------
if [[ ! -f "$CANONICAL_HELPERS" ]]; then
  echo "error: canonical helpers not found at $CANONICAL_HELPERS" >&2
  exit 1
fi
for fn in "${HANDLERS[@]}"; do
  dest="$SRC_DIR/$fn"
  if [[ ! -d "$dest" ]]; then
    echo "warn: handler dir $dest missing — skipping" >&2
    continue
  fi
  cp "$CANONICAL_HELPERS" "$dest/helpers.py"
done
echo "vendor_prompts: helpers.py synced into ${HANDLERS[*]}"

# --- 2. vendor prompts -------------------------------------------------------
shopt -s nullglob
prompt_files=("$PROMPTS_DIR"/*.md)
shopt -u nullglob

if [[ ${#prompt_files[@]} -eq 0 ]]; then
  echo "warn: no prompt files in $PROMPTS_DIR — handlers will use built-in" \
       "fallback prompts. (Sage's SAGE-01..05 not delivered yet.)" >&2
  exit 0
fi

for fn in "${HANDLERS[@]}"; do
  dest="$SRC_DIR/$fn/prompts"
  [[ -d "$SRC_DIR/$fn" ]] || continue
  mkdir -p "$dest"
  cp "${prompt_files[@]}" "$dest/"
done
echo "vendor_prompts: ${#prompt_files[@]} prompt file(s) vendored into ${HANDLERS[*]}"
echo "vendor_prompts: done — safe to run 'sam build'"
