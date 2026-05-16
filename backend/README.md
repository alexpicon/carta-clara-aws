# Carta Clara — Backend

AWS infrastructure for Carta Clara. One SAM template provisions everything.

---

## Prerequisites

1. **AWS CLI** configured: `aws configure` against the team account, region `us-west-2`.
2. **AWS SAM CLI** installed: `brew install aws-sam-cli`
3. **Python 3.12** for local Lambda development.
4. **Bedrock model access requested** in `us-west-2` console for:
   - Anthropic Claude Sonnet 4.x
   - Amazon Nova Pro
   - Amazon Titan Embed Text v2
   - (Optional) Amazon Nova Sonic

Verify access: `aws bedrock list-foundation-models --region us-west-2 | grep claude`

---

## First-time deploy

```bash
cd backend
./scripts/vendor_prompts.sh   # REQUIRED before every build — see "Deploy step" below
sam build
sam deploy --guided
```

Answer prompts:
- Stack name: `carta-clara-mvp` (default)
- Region: `us-west-2` (default)
- Confirm changes: `Y`
- Allow IAM role creation: `Y`
- Disable rollback: `N`
- Save to samconfig: `Y`

On success, copy the `ApiBaseUrl` output. That's the URL the iOS app calls.

---

## Subsequent deploys

```bash
make build && sam deploy      # 'make build' = vendor_prompts.sh + sam build
```

Or, while developing, use sync for fast iteration:

```bash
sam sync --watch
```

---

## What this template creates

| Resource | Purpose |
|----------|---------|
| `carta-clara-uploads-<account>-<region>` (S3) | Ephemeral document storage, 1-day lifecycle (1h target via tagging) |
| `carta-clara-refusal-log` (DynamoDB) | PII-redacted log of refusals; session_id + ts composite key; DynamoDB TTL on `ttl` attribute |
| `LambdaExecutionRole` (IAM) | Bedrock InvokeModel / Retrieve / ApplyGuardrail, S3 R/W, DynamoDB R/W, Polly Synthesize, Transcribe stream |
| `carta-clara-scan` (Lambda) | POST /scan — multimodal extract + summary + audio URL |
| `carta-clara-ask` (Lambda) | POST /ask — bounded chat with Guardrails-enforced refusal |
| `carta-clara-refusal-log` (Lambda) | GET /refusal-log — visible trust counter |
| `carta-clara-api` (API Gateway HTTP API) | Front door for the iOS app |

---

## What's NOT in this template (intentional)

These live in the Bedrock console — easier to iterate during the hackathon:

- **Knowledge Base** (`carta-clara-kb`) — create in console, point at `kb-corpus/` after uploading to S3.
- **Guardrail** (`carta-clara-guard`) — create in console with denied topics, PII filter, contextual grounding.
- **Bedrock Agent** (optional) — only if your orchestration outgrows direct Bedrock calls.

After creating these, update the SAM stack parameters:

```bash
sam deploy \
  --parameter-overrides \
    KnowledgeBaseId=YOUR_KB_ID \
    GuardrailId=YOUR_GUARDRAIL_ID \
    GuardrailVersion=1
```

---

## Handler code layout

```
src/
  _shared/helpers.py   canonical shared helpers (KODA-08) — see src/_shared/README.md
  scan/handler.py      POST /scan        + vendored helpers.py
  ask/handler.py       POST /ask         + vendored helpers.py
  refusal_log/handler.py  GET /refusal-log + vendored helpers.py
tests/
  test_scan.py  test_ask.py  test_refusal_log.py  test_shared_vendored.py
  conftest.py   events/{scan,ask,refusal_log}.json
```

`helpers.py` is **vendored** (copied) into each handler directory: SAM packages
each function from its own `CodeUri`, so a function cannot import a sibling
`_shared/` package at runtime. Edit `src/_shared/helpers.py`, then re-vendor:

```bash
for d in scan ask refusal_log; do cp src/_shared/helpers.py src/$d/helpers.py; done
```

`tests/test_shared_vendored.py` fails the build if a copy drifts.

### Prompts

Handlers load prompts (`extraction_prompt.md`, `spanish_summary_prompt.md`,
`system_prompt.md`, `ask_prompt.md`) authored by Sage in `backend/prompts/`.
The loader (`helpers.load_prompt`) searches, in order: the handler directory,
`src/prompts/`, `backend/prompts/`, then `$PROMPTS_DIR`. If a prompt is missing
it falls back to a built-in safe prompt so handlers still run.

> **Deploy step (required):** because `backend/prompts/` is outside each
> function's `CodeUri`, the prompt files must be copied into each handler dir
> before `sam build`. Run the vendoring script — or just use `make build`,
> which runs it for you:
>
> ```bash
> ./scripts/vendor_prompts.sh   # copies helpers.py + prompts/*.md into each handler dir
> ```
>
> The script is idempotent and also re-syncs `helpers.py` from
> `src/_shared/`. If Sage's prompts are not present yet it warns and exits 0
> (handlers fall back to built-in prompts). Recommended long-term fix: a Lambda
> layer (needs a `template.yaml` change).

### Build shortcuts (`make`)

```
make vendor   copy helpers.py + Sage's prompts into each handler dir
make build    vendor, then sam build
make deploy   vendor, sam build, sam deploy
make test     run the pytest smoke suite
make clean    remove build artifacts and vendored prompt dirs
```

---

## Environment variables

All Bedrock/Guardrail/model IDs come from `template.yaml` parameters (see that
file's `Parameters` block). One **optional** variable is read by the handler
code beyond the template defaults:

| Variable | Required | Purpose |
|----------|----------|---------|
| `PROMPTS_DIR` | optional | Extra search path for the prompt loader. Unset in normal deploys. |

After creating the Bedrock Knowledge Base + Guardrail in the console, wire the
IDs in (until then, handlers run without the KB and skip the Guardrail, logging
a warning):

```bash
sam deploy --parameter-overrides \
  KnowledgeBaseId=YOUR_KB_ID GuardrailId=YOUR_GUARDRAIL_ID GuardrailVersion=DRAFT
```

---

## Running tests

Smoke tests mock every AWS client — no account or network needed.

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r tests/requirements.txt
python -m pytest tests/ -v
```

17 tests cover the three handlers including the Guardrail refusal path. The
test image is a 100x100 PNG embedded in `tests/conftest.py`.

### Local invoke against the built artifact

```bash
sam build
sam local invoke ScanFunction      --event tests/events/scan.json
sam local invoke AskFunction       --event tests/events/ask.json
sam local invoke RefusalLogFunction --event tests/events/refusal_log.json
```

`sam local invoke` runs the real handler in Docker and makes real AWS calls
(Bedrock, S3, Polly, DynamoDB) — credentials and the deployed S3/DynamoDB
resources must exist. Use `pytest` for offline checks; use `sam local invoke`
to verify wiring against live AWS.

---

## Viewing CloudWatch logs

Handlers emit structured JSON logs (`{"level": ..., "msg": ...}`). Tail them:

```bash
sam logs --stack-name carta-clara-mvp --name ScanFunction --tail
sam logs --stack-name carta-clara-mvp --name AskFunction --tail
sam logs --stack-name carta-clara-mvp --name RefusalLogFunction --tail
```

Or with the AWS CLI directly:

```bash
aws logs tail /aws/lambda/carta-clara-scan        --follow --region us-west-2
aws logs tail /aws/lambda/carta-clara-ask         --follow --region us-west-2
aws logs tail /aws/lambda/carta-clara-refusal-log --follow --region us-west-2
```

Useful log markers: `guardrail_not_configured`, `prompt_not_found`,
`kb_retrieve_failed`, `transcribe_timeout`, `*_unhandled`.

---

## Tearing down

```bash
sam delete --stack-name carta-clara-mvp
```

---

## Troubleshooting

**`AccessDeniedException` on Bedrock invoke**
→ Model access not granted yet. Wait 5–30 min after requesting in console.

**S3 bucket already exists**
→ Account+region combination yields a bucket name that's taken. Change the template's `BucketName` to add a unique suffix.

**Lambda timeout on first invoke**
→ Cold start. Bedrock multimodal can take 5–8s the first time. Increase `Timeout: 30` to `60` if needed.

**Guardrail blocks legitimate queries**
→ Threshold too aggressive. Lower contextual grounding from 0.7 → 0.6 in the Guardrail console.
