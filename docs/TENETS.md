# Carta Clara — Tenets

These are the bright lines that govern every product and engineering decision. When you're tempted to add a feature, check this list first. If the feature violates a tenet, the feature doesn't ship — full stop.

Tenets are listed in priority order. When two conflict, the higher-numbered one yields.

---

## 1. Trust before features

Every feature must visibly demonstrate trustworthiness before it demonstrates capability. The visible PII redaction, the refusal counter, the citation chips, the "we will not give legal advice" disclaimer — these come before the cool stuff, not after.

## 2. Refuse before answering

When in doubt, refuse and route to a human. A refusal that routes to free legal aid is a feature, not a failure. A graceful "I can't help with that, but [free legal aid clinic] can — here's their number" is the strongest moment in the demo.

## 3. Information, not advice

The product can explain what a document says, what's urgent, who's named in it, what categories of evidence exist, and what questions to ask a lawyer. It cannot tell the user what legal strategy to use, whether to admit or deny anything, whether they qualify for any relief, or what to say to ICE / a judge / an officer.

## 4. Citations are the proof

Every grounded claim displays its source. Every refusal displays the alternative ("ask a lawyer; here are three free ones"). The user can always tap to verify.

## 5. The customer is grandma

Every design decision is judged against one specific person: a 70-year-old Spanish-speaking grandmother holding a USCIS letter at 9pm, with her granddaughter on the phone. If she can't use it one-handed, with arthritis, in 30 seconds, it isn't done.

## 6. Synthetic data only, always

We never use real immigration documents in the product, the demo, the screenshots, the Devpost submission, or anywhere else. Every demo doc is watermarked `DEMO – NOT A REAL CASE`. This is permanent — not a hackathon constraint.

## 7. Ephemeral by default

User documents have a 1-hour TTL in S3. We do not store immigration documents. Our DynamoDB log records refusal events (PII-redacted) and session metadata only — never document content.

## 8. The architecture is the trust story

We use Amazon Bedrock Guardrails, AWS-managed services, and an explicit deny-list because these are the building blocks Amazon designed for responsible AI. The architecture decision IS the trust decision.

## 9. One language, polished

Spanish only for MVP. Adding a half-baked second language hurts the demo more than a single excellent language helps. Korean, Hindi, Mandarin, Tagalog are roadmap.

## 10. The roadmap is the Think Big

What we deliberately did not build is part of the story. Every "we considered this and didn't ship it" is a Think Big moment — provided we can articulate why.

---

## Bright lines that NEVER move

- Substantive responses to USCIS / EOIR / ICE / DHS / a court — never drafted by the product.
- Judge analytics / decision statistics / past-case matching — never shipped.
- Real immigration documents — never used.
- "Should I…" questions about legal strategy — always refused, always routed.

If anyone on the team proposes crossing one of these, the answer is no without debate.
