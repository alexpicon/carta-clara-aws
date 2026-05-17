# Carta Clara — 10-Minute Pitch Plan

Structure: customer-first opening → live demo → architecture + leadership principles → roadmap + close. Each segment has speaker notes, a visual, and a backup if something fails.

Companion to `docs/DEMO_SCRIPT.md` (which covers the 3-minute demo beats in isolation). This file is the full 10-minute pitch wrapper.

---

## Segment 1 — The customer (0:00 → 1:30)

**Goal:** establish the human stakes before showing technology.

**Slide:** photo of a kitchen counter with a USCIS envelope. Wordmark "Carta Clara." No tech.

**Speaker (verbatim, ~90 sec):**

> "Every immigrant family knows this moment: an official-looking letter arrives in English, the household stops, and a child is handed a phone to translate something a child should never have to translate alone.
>
> The translators that exist today give you words. They don't tell you what's urgent. They don't tell you when to call a lawyer. They definitely don't tell you when to stop and not answer.
>
> We built Carta Clara for our grandmothers. It turns a frightening English letter into a plain summary in their language, a deadline, a scam check, and a printable packet for a free immigration attorney — in under 30 seconds. And it refuses, every time, when a question crosses into legal strategy."

**LP call-out (verbal, brief):** *Customer Obsession* — the customer is one specific person: a 70-year-old Spanish-speaking grandmother holding a USCIS letter at 9pm.

---

## Segment 2 — What it does, in 4 promises (1:30 → 2:30)

**Goal:** preview the demo so judges know what to look for.

**Slide:** 4 bullets, big text:

1. **Translate** any English document to plain Spanish (or English) in <30s
2. **Show** what's urgent and what's not
3. **Warn** about notario / immigration-scam patterns from FTC + USCIS sources
4. **Refuse** legal-strategy questions and route to free legal aid

**Speaker (~60 sec):** "Four promises. Watch all four happen in the next three minutes."

---

## Segment 3 — Live demo (2:30 → 6:00)

**Goal:** prove the four promises, beat by beat. **3 min 30 sec**, timed.

**Setup before the talk:**

- Synthetic NTA from `docs/synthetic-docs/NTA_demo.md` printed on real paper, watermarked `DEMO – NOT A REAL CASE`
- iPhone connected to projector via mirroring (test the adapter on the venue's actual HDMI before going on)
- **Have the backup 90-second video pre-loaded** in QuickTime. If the live demo stalls past 30s on the spinner, switch to video without apologizing — just keep narrating.

**Demo script (timed):**

| Time | Action | Narration |
|---|---|---|
| 0:00 | Tap shutter on printed synthetic NTA | "I'm photographing a Notice to Appear — a synthetic document I authored with my team. We never use real documents in the demo." |
| 0:05 | Confirm photo | "I confirm the photo." |
| 0:08 | Language picker → tap **Español** | "I choose Spanish — the same choice grandma would make." |
| 0:12 | Redaction animation plays | "Before the photo leaves the phone, you see this: visible redaction of every piece of personal information. Trust before features." |
| 0:18 | While scan runs, narrate | "While the AI works, notice the refusal counter in the corner. It's empty right now. Watch it during the chat." |
| 0:35 | Results render | "Here it is. **Summary** in plain Spanish. **Important date**: October 15, 2026. **Who sent this**: Department of Homeland Security. **What they say**: overstay of B-2 visa, INA section 237(a)(1)(B) — in plain words. **Your rights**: free interpreter, free lawyer." |
| 1:00 | Tap **Listen to the summary** — Polly Spanish plays | "And it reads it aloud, because grandma may prefer to listen." (Let it play 5 seconds, then mute.) |
| 1:10 | Slide reading-level to **Full** | "And the slider expands every section into more detail for the helper on the phone with her." |
| 1:25 | Tap **Ask about this document** | "Now the dangerous moment: a question that needs a lawyer." |
| 1:30 | Say out loud: *"Should I argue asylum based on these allegations?"* | "Watch what happens." |
| 1:40 | Refusal renders + counter ticks to 1 | "It refuses. Visibly. The counter ticks up. And it routes to Northwest Immigrant Rights Project — a real Seattle clinic, with their real phone number. **The refusal is the feature.**" |
| 2:00 | Tap **Help me respond** | "And here's what grandma brings to that free legal appointment." |
| 2:10 | Show Preparation Packet preview | "Translated summary, evidence checklist, pre-filled extension request, phone-call script, questions for the lawyer, and a cover sheet that says 'Bring this to your appointment.'" |
| 2:30 | Tap **Find free legal help** | "Three free Seattle clinics. Tap a phone number and the dialer opens." |
| 2:50 | **Curveball:** scan a second synthetic doc — the notario SMS | "And because the architecture is general, the same flow handles a notario scam SMS. Scam red-flag card lights up, citing the FTC source. Same trust stack, different document." |
| 3:25 | Return to home screen | "30 seconds per scan. No accounts. Nothing stored after 1 hour. Free to the user." |

**LP call-outs during demo (don't break flow, just plant the phrases):**

- "Trust before features" (Earn Trust)
- "The refusal is the feature" (Customer Obsession + Earn Trust)
- "Real Seattle clinic, real phone number" (Earn Trust)

---

## Segment 4 — Architecture + the trust stack (6:00 → 7:30)

**Goal:** show this isn't a prompt-in-a-box; it's an AWS product.

**Slide:** architecture diagram (export from `docs/ARCHITECTURE.md`)

**Speaker (~90 sec):**

> "Six AWS services. One SAM template provisions the whole thing.
>
> **Amazon Textract** reads the document text — purpose-built for documents, faster and cheaper than asking a foundation model to do OCR. **Amazon Bedrock with Claude Sonnet 4.6** does the semantic work — understanding which date is the hearing date, which statute is cited, what's an allegation versus a fact. **Amazon Polly** with the neural Lupe voice reads the Spanish summary aloud. **Amazon S3** holds documents for exactly one hour, then deletes them. **Amazon DynamoDB** stores only the refusal events — what the app refused to do, never what the user asked. And **Amazon Bedrock Guardrails** enforces the denied topics and PII masking.
>
> Treating this like an AWS product, not a prompt. One CloudFormation template, six services, four of them Bedrock, no fine-tuning."

**LP call-out (verbal):**

- *Invent and Simplify* — one SAM template, end-to-end provisioning
- *Frugality* — Textract for OCR instead of paying for multimodal tokens

---

## Segment 5 — Leadership principles, deliberately (7:30 → 8:30)

**Goal:** name the LPs explicitly. Judges look for this. Pick **four** and own them.

**Slide:** four cards, each one LP + one sentence proof.

**Speaker (~60 sec):**

> **Customer Obsession** — every feature passes the grandma test: can a 70-year-old Spanish speaker use it one-handed, in 30 seconds, with arthritis? If no, it doesn't ship.
>
> **Earn Trust** — visible redaction. Visible refusals. Citations on every claim. A trust counter the user can tap. The architecture is the trust story.
>
> **Think Big** — the same trust stack works for utility shutoff notices, school discipline letters, IRS letters, lease violations. Anywhere a frightening English document lands on a kitchen counter in America. Immigration is the launch vertical because that's where the fear is greatest.
>
> **Insist on the Highest Standards** — we maintain a 25-prompt evaluation suite, 15 adversarial and 10 grounded. Synthetic documents only, watermarked. A bright-line list of things the product will never do — judge analytics, drafting responses to ICE, predicting outcomes. These don't move.

---

## Segment 6 — What we deliberately did NOT build (8:30 → 9:15)

**Goal:** Think Big requires showing you considered the alternatives. This is the strongest slide.

**Slide:** "We considered. We didn't ship. Here's why."

**Speaker (~45 sec):**

> "Three things we explicitly cut:
>
> An **AI immigration lawyer**. We will never call this product that. It's a translator that knows when to refuse. That decision is permanent.
>
> **Judge analytics** — predicting how a specific judge rules. The data exists. The math is easy. The harm is enormous. We will not ship it.
>
> **Real documents in the demo**. Every screenshot, every video, every Devpost frame uses a synthetic document. The bright line does not move for anything externally visible."

**LP call-out:** *Have Backbone; Disagree and Commit* — saying no is harder than saying yes.

---

## Segment 7 — Roadmap + close (9:15 → 10:00)

**Slide:** three small icons: Korean, Hindi, Mandarin — and one big icon: "Other frightening documents."

**Speaker (~45 sec):**

> "Roadmap. Korean, Hindi, Mandarin, Tagalog — each language launches only when a native speaker on the team validates every output. We refuse to ship a language we cannot verify.
>
> Other document types — same architecture, same trust stack, different knowledge base.
>
> We built Carta Clara with gratitude — for the people who got us here, and for the moments AI should be careful, cited, and humble.
>
> Thank you."

---

## Timing checkpoint table (memorize these)

| Time | Where you should be |
|---|---|
| 1:30 | Done with customer story |
| 2:30 | Done with 4-promises slide |
| 4:30 | Halfway through demo (refusal moment) |
| 6:00 | Demo wrapping, transitioning to architecture |
| 7:30 | Architecture done |
| 9:00 | Leadership principles done |
| 10:00 | Bow |

---

## Backup plan (if something breaks on stage)

| Failure | Backup |
|---|---|
| Scan takes >40s | Switch to pre-recorded 90-sec demo video. Don't apologize, just keep narrating. |
| Camera fails | Use the bundled demo document path (`loadDemoDocument()` — tap the small "Use the demo document" link on splash). |
| Network drops | The 90-sec video. Same narration. |
| Polly audio doesn't play | Skip the listen tap. The card still shows the text. Move on. |
| Judge asks something not in FAQ | Two-second pause. Then: "Honest answer — I don't know. I'd want to test that before claiming. Here's how I'd find out: [give the method]." |

---

## Who does what on stage (3-person team)

- **PM/Pitcher (Alex):** owns the words, the laptop, the slides. Stands center.
- **iOS lead:** holds the iPhone for the demo, taps through. Practices the demo until they can do it without looking.
- **Backend lead:** holds the FAQ binder. If a judge asks a deep technical question, they step in.

---

## One thing you have to do today before pitch

**Three dress rehearsals.** Full 3-min demo timed. Find where it drags, find where the slider doesn't render fast enough, find where a section title is too long for the card. Three runs. The first one will be ugly. The second exposes the real issues. The third is the one you'll perform on stage.

The script above is for one person, but the most important second person at the rehearsal is the timer-holder. They call out the timestamps. You feel where you're falling behind.

---

## Cross-references

- 3-minute demo beats (the demo portion of this plan, in isolation): `docs/DEMO_SCRIPT.md`
- Judge Q&A prep: `docs/FAQ.md`
- The product story (working backwards): `docs/PRESS_RELEASE.md`
- The bright lines: `docs/TENETS.md`
- Architecture diagram source: `docs/ARCHITECTURE.md`
- Slide-deck text content: `docs/SLIDE_DECK.md`
- Eval numbers (the proof slide): `docs/EVAL_PROMPTS_EXPECTED.md`
