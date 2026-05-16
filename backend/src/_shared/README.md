# `_shared` — shared Lambda helpers (KODA-08)

`helpers.py` here is the **canonical source** for code shared across the three
Carta Clara Lambda handlers (`scan`, `ask`, `refusal_log`):

- HTTP response builder + event body parsing
- lazy boto3 client/resource construction
- prompt loader (`backend/prompts/` → handler-local fallback)
- Bedrock `Converse` wrapper with the Guardrail attached on every call
- Bedrock Knowledge Base retrieval
- S3 ephemeral put / get / presign
- Polly Spanish synthesis
- refusal taxonomy (Guardrail topic → API_CONTRACT reason → Spanish label)
- legal-aid clinic list + default safe-replacement text

## Why this is vendored (copied), not imported

SAM packages every function from its own `CodeUri` (`src/scan/`, `src/ask/`,
`src/refusal_log/` in `template.yaml`). A function **cannot** import a sibling
directory such as `src/_shared/` at runtime — it is not inside the function's
deployment artifact.

Two ways to share code: a Lambda layer, or vendoring. A layer needs a
`template.yaml` change, which is outside Koda's write scope
(`backend/src/`, `backend/tests/` only). So `helpers.py` is **copied verbatim**
into each handler directory, and handlers do a same-directory `import helpers`.
This keeps one logical source of truth and guarantees `sam build && sam deploy`
works against the existing template with zero changes.

## Editing shared code

Edit **this** file, then re-vendor:

```bash
cd backend
for d in scan ask refusal_log; do cp src/_shared/helpers.py src/$d/helpers.py; done
```

`backend/tests/test_shared_vendored.py` fails if the copies drift.

## Recommendation for Claudio (post-hackathon)

If the team is willing to touch `template.yaml`, promoting `_shared/` (and
`backend/prompts/`) to a Lambda **layer** removes the vendoring step. Logged in
`docs/worklog/koda.md` as a non-blocking recommendation.
