# Carta Clara

A native iPhone app that turns frightening English mail into a plain-Spanish summary, a deadline card, a scam/notario warning, a Response Preparation Packet for legal aid, and a safe refusal whenever the question crosses into legal strategy.

Built for the Seattle University AWS Hackathon. Track: **Building with Bedrock**.

---

## What this repo contains

```
carta-clara/
├── README.md                    ← you are here
├── docs/                        ← the source of truth (read first)
│   ├── PHASE_PLAN.md            ← what to do, when, who owns it
│   ├── TENETS.md                ← the bright lines (read before you build anything)
│   ├── PRESS_RELEASE.md         ← what the product is, in customer language
│   ├── FAQ.md                   ← Devpost write-up + judge Q&A prep
│   ├── DEMO_SCRIPT.md           ← the 3-minute pitch, beat by beat
│   ├── ARCHITECTURE.md          ← system design, data flow, AWS services
│   └── synthetic-docs/          ← demo NTAs, RFEs — DEMO ONLY, never real
├── backend/                     ← AWS Lambda + Bedrock + SAM
│   ├── template.yaml            ← one SAM template provisions everything
│   ├── samconfig.toml           ← deployment defaults
│   ├── README.md                ← deploy instructions
│   └── src/
│       ├── scan/                ← POST /scan — multimodal extract + cards
│       ├── ask/                 ← POST /ask  — bounded chat about a document
│       └── refusal_log/         ← GET  /refusal-log — visible trust counter
├── ios/                         ← Swift / SwiftUI app
├── kb-corpus/                   ← curated Knowledge Base source documents
└── outreach/                    ← validation outreach to immigrant-services orgs
```

---

## How to start (by role)

| If you're the… | Start here |
|----------------|------------|
| **PM / Pitch / Demo** | `docs/PRESS_RELEASE.md` → `docs/PHASE_PLAN.md` → `docs/DEMO_SCRIPT.md` |
| **iOS engineer** | `docs/PHASE_PLAN.md` → `ios/` → build against the API URL in `backend/README.md` |
| **Backend engineer** | `backend/README.md` → deploy SAM → fill in `backend/src/*/handler.py` |
| **Bedrock / RAG engineer** | `docs/TENETS.md` → `kb-corpus/` → AWS console for KB + Guardrails |
| **Validation outreach** | `outreach/EMAIL_TEMPLATE.md` → `outreach/OUTREACH_LOG.md` |

---

## Non-negotiable rules (read these first)

1. **No real immigration documents.** Synthetic only, watermarked `DEMO – NOT A REAL CASE`.
2. **No legal advice.** The product refuses legal-strategy questions and routes to legal aid.
3. **PII redacted before any model call.** Visible in the UI.
4. **Spanish-only for MVP.** Korean / Hindi / others are roadmap.
5. **No accounts.** Ephemeral session. S3 1-hour TTL.
6. **Sunday 8am = scope freeze.** Anything not working by then doesn't ship.

Full tenets: `docs/TENETS.md`.

---

## Submission targets

- 3-minute YouTube/Vimeo demo video
- Devpost project page (description, screenshots, architecture diagram)
- This GitHub repo (public)
- Optionally: TestFlight build (Apple Developer account in hand)
- Pitch: 3-minute live demo + Q&A
