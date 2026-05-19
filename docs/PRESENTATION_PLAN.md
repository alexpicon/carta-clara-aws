# Carta Clara — Presentation Plan (current build)

> **This supersedes `docs/PITCH_PLAN.md`.** That file pitched features that no longer ship (a pre-filled extension-request letter) and a language-picker beat that isn't in the current build. Use **this** file to rehearse. `PITCH_PLAN.md` is kept only for history.
>
> Format: ~10-minute final pitch + live demo. Hackathon **track: Amazon Bedrock**. Hackathon **prompt: "Building with gratitude."**

---

## The one thing the presentation is about

If you forget everything else, remember this sentence. It is the answer to "what is our presentation about":

> **Carta Clara is what gratitude looks like as software — an AI grateful enough to know its limits. It explains a frightening letter, it warns about scams, and it refuses the questions only a lawyer should answer. Built on Amazon Bedrock, for the grandmothers who built our families.**

"Building with gratitude" is not the closing line. It is the **spine**. Gratitude shows up three times, and the deck is structured around all three:

1. **Gratitude to the people who came before** — we built this *for our grandmothers*, the immigrants who built our families. (Slides 2–3)
2. **Gratitude as humility in the AI itself** — a grateful AI knows what it is *not*. It refuses, cites, and hands the hard questions to a human. (Demo + Bedrock slide)
3. **Gratitude to the people and tools doing the real work** — the free legal-aid clinics, and Amazon Bedrock's responsible-AI building blocks. (Bedrock slide + close)

That is the through-line. Every slide plants one of those three.

---

## What changed since `PITCH_PLAN.md` (read before rehearsing)

| Old plan said | Current build |
|---|---|
| Packet includes a "pre-filled extension request" letter | **Removed.** It implied a legal recommendation (whether to ask for more time is the lawyer's call). Packet now: translated summary, deadline, documents to gather, phone-call script, questions for the lawyer, cover sheet. |
| Demo beat: "Language picker → tap Español" | **Restored.** The LanguagePickerView is live right after the splash, before the camera opens — user taps Spanish or English (Español is the primary button), and every screen from there on (camera tips, camera, cards, UI chrome, errors, Polly audio) respects the choice. |
| "Six AWS services" listed loosely | Six services, **four of them Bedrock** (multimodal model, fast model, Knowledge Base, Guardrails) + Lambda + API Gateway. Textract, Polly, Transcribe, S3, DynamoDB, SAM are utilities. |
| 3 Lambda functions | **4 Lambdas**: `scan`, `ask`, `scan_packet`, `refusal_log`. |

---

## Slide-by-slide deck (12 slides)

Each slide below gives: **ON SLIDE** (what the audience sees — keep it sparse), **SAY** (speaker notes), and **PLANTED** (the Leadership Principle woven in — *never written on a slide*, see the cheat sheet at the end).

---

### Slide 1 — Title (0:00 → 0:20)

**ON SLIDE:** Wordmark "Carta Clara." Below it, smaller: *Built with gratitude.* No tech, no logos.

**SAY:** "This is Carta Clara. We built it with gratitude — and I'll show you exactly what that means."

---

### Slide 2 — The moment (0:20 → 1:40)

**ON SLIDE:** A photo of a kitchen counter with an official USCIS envelope on it. Nothing else.

**SAY (~80 sec):**
> "Every immigrant family knows this moment. An official letter arrives, in English. The household goes quiet. And a child gets handed a phone to translate something a child should never have to translate alone.
>
> The translation apps that exist give you *words*. They don't tell you what's urgent. They don't tell you when to call a lawyer. And they definitely don't tell you when to stop — when a question is one only a lawyer should answer.
>
> We each have someone in our family who has stood at that counter. We built Carta Clara for them."

**PLANTED:** *Customer Obsession* — one specific person, not a market segment.

---

### Slide 3 — Why we built it (1:40 → 2:20)

**ON SLIDE:** One line of text: *"For the grandmothers who built our families."*

**SAY (~40 sec):**
> "This is the gratitude the hackathon asked us to build with. Not gratitude as a thank-you at the end of a project — gratitude as the *reason* for the project. The people who immigrated before us took the hardest version of this moment, with no tool at all. Carta Clara is what we owe them. Everything you're about to see is designed for one 70-year-old woman holding a letter at 9pm."

**PLANTED:** *Customer Obsession* (the grandma test).

---

### Slide 4 — Four promises (2:20 → 3:00)

**ON SLIDE:** Four bullets, large type:
1. **Explain** any English document in plain Spanish — in under 30 seconds
2. **Flag** what's urgent: the deadline, the next action
3. **Warn** about notario / immigration-scam patterns (FTC + USCIS sources)
4. **Refuse** legal-strategy questions — and route to a free lawyer

**SAY (~40 sec):** "Four promises. Watch all four happen live in the next three minutes. Keep your eye on the fourth — the refusal — because that's the one that makes this trustworthy."

**PLANTED:** *Earn Trust* (the refusal previewed as a feature).

---

### Slide 5 — LIVE DEMO (3:00 → 6:00)

**ON SLIDE:** Just the wordmark + "Live demo" — a holding slide. The phone mirror is the real content.

**Demo beats (timed, ~3 min). Synthetic NTA, watermarked `DEMO – NOT A REAL CASE`, printed on paper.**

| Time | Action | Narration |
|---|---|---|
| 0:00 | Tap shutter on the printed synthetic NTA | "I'm photographing a Notice to Appear — a synthetic document my team authored. We never use a real one." |
| 0:06 | Redaction animation plays | "Before the photo leaves the phone, you see this: every piece of personal information visibly masked. Trust before features — you see the redaction happen." |
| 0:14 | Scan runs; point at the corner | "While the AI works — see the refusal counter in the corner. It's at zero. Watch it later." |
| 0:30 | Results render | "Here it is. **Plain-language summary.** **The date that matters:** October 15, 2026. **Who sent it:** Department of Homeland Security. **What they claim:** a B-2 visa overstay — in plain words, not statute numbers. **Your rights:** a free interpreter, a free lawyer." |
| 0:55 | Tap **Listen** — Polly Spanish plays | "And it reads aloud, because grandma may prefer to listen." (Play 5 sec, mute.) |
| 1:05 | Drag the reading-level slider to **Full** | "The slider expands every section into more detail — for the family member helping her." |
| 1:20 | Tap **Ask about this document**; say aloud: *"Should I argue asylum based on these allegations?"* | "Now the dangerous moment — a question that needs a lawyer, not an app." |
| 1:35 | Refusal renders; counter ticks 0 → 1 | "It refuses. Visibly. The counter ticks up. And it routes her to Northwest Immigrant Rights Project — a real Seattle clinic, real phone number. **The refusal is the feature.** A grateful AI knows what it isn't." |
| 2:00 | Tap **Help me respond** | "Here's what she brings to that free appointment." |
| 2:10 | Show the Preparation Packet preview | "Translated summary, her deadline, the documents to gather, a phone-call script for the clinic, the questions to ask the lawyer, and a cover sheet: 'Bring this to your appointment. Your lawyer writes the official response.' We do not draft it for her — that's the lawyer's job." |
| 2:30 | Tap **Find free legal help** | "Three free Seattle clinics. Tap a number, the dialer opens." |
| 2:45 | **Curveball:** scan the synthetic notario-scam SMS | "Because the architecture is general, the same flow handles a notario-scam text. The scam red-flag card lights up — citing the FTC source. Same trust stack, different document." |

**PLANTED during demo (say the phrases, don't break stride):** "Trust before features" / "The refusal is the feature" / "real Seattle clinic, real phone number" → *Earn Trust*. "We do not draft it for her" → *Have Backbone*.

---

### Slide 6 — Recap of the demo (6:00 → 6:15)

**ON SLIDE:** The four promises from Slide 4, now each with a checkmark.

**SAY (~15 sec):** "Four promises, all four kept. 30 seconds a scan. No account. Nothing stored past one hour. Free to the person holding the letter."

**PLANTED:** *Ownership* — "nothing stored past one hour" (we own the user's safety, not their data).

---

### Slide 7 — Amazon Bedrock: the trust stack (6:15 → 7:30)

**ON SLIDE:** Four boxes — *Claude Sonnet 4.6 (multimodal)*, *Nova Pro (fast model)*, *Knowledge Bases*, *Guardrails* — under one heading: **Amazon Bedrock.**

**SAY (~75 sec):**
> "This is the Bedrock track, and Bedrock is not a detail of our build — it *is* the build. Four Bedrock capabilities, each doing one job:
>
> **Claude Sonnet 4.6** — does the semantic work on the OCR'd text Textract returns: which date is the hearing, which line is an allegation versus a fact, all in the user's chosen language. We deliberately use Textract for OCR and Claude for understanding — each tool doing what it's best at.
>
> **Nova Pro** — the fast model for follow-up questions, so the chat stays quick.
>
> **Bedrock Knowledge Bases** — managed retrieval over a curated corpus: USCIS, the FTC, the EOIR practice manual, Seattle legal aid. Every claim the app makes is grounded in a real source, with a citation the user can tap. We wrote zero vector-database code.
>
> **Bedrock Guardrails** — wired in for ten denied topics, a PII filter, and contextual grounding. To be honest with you: for this hackathon the Guardrail ID is still `PLACEHOLDER`, so the refusals you saw are enforced at the prompt level today. The plumbing is in place; flipping the ID to the live Guardrail is the immediate post-hackathon work. We picked Bedrock specifically so the safety layer we *don't* have to invent is there waiting."

**PLANTED:** *Earn Trust* (enforced, not prompted) + gratitude layer 3 (grateful for the building blocks).

---

### Slide 8 — One file builds the whole thing: CloudFormation (7:30 → 8:20)

**ON SLIDE:** A simple diagram — one box `template.yaml` → arrow labeled `sam deploy` → a cloud containing: *4 Lambdas · API Gateway · S3 · DynamoDB · IAM roles.*

**SAY (~50 sec):**
> "A judge will ask how this is deployed. Here's the honest, simple answer.
>
> Everything in our cloud is described in **one text file** — `template.yaml`. We write it in **AWS SAM**, which is shorthand for **CloudFormation** — AWS's infrastructure-as-code engine. One command, `sam deploy`, hands that file to CloudFormation, and CloudFormation builds all of it: four Lambda functions, the API, the storage, the database, the permissions. One command tears it all down again — nothing orphaned, no surprise bill.
>
> That's deliberate. With a 36-hour clock, infrastructure you can rebuild from one file in minutes is infrastructure you can trust. We treated this like an AWS product, not a prompt in a box."

**PLANTED:** *Invent and Simplify* ("one file, one command") + *Frugality* ("nothing orphaned, no surprise bill").

> **Note:** the Bedrock Knowledge Base and Guardrails are created in the console, not in the template — say so only if asked. Their IDs pass into the stack as parameters.

---

### Slide 9 — The proof (8:20 → 8:50)

**ON SLIDE:** Five numbers. **Fill in the actual measured numbers before the pitch — these are the targets:**
- Refusal accuracy: __ / 15 adversarial prompts (target ≥ 14)
- False refusals: __ / 10 control prompts (target 0)
- Grounding accuracy: __ / 5 cite the correct source (target ≥ 4)
- Latency p50: __ s (target ≤ 15)
- Latency p95: __ s (target ≤ 25)

**SAY (~30 sec):** "We don't ask you to trust the claim — here are the numbers. A 25-prompt evaluation suite: 15 adversarial, 10 control. This is how we know the refusal works, and how we know it doesn't refuse the wrong things."

**PLANTED:** *Insist on the Highest Standards* + *Are Right, A Lot* (measured, not asserted).

---

### Slide 10 — What we refused to build (8:50 → 9:25)

**ON SLIDE:** Heading "We considered. We didn't ship. Here's why." Three items: *An "AI immigration lawyer" · Judge analytics · Real documents in the demo.*

**SAY (~35 sec):**
> "Gratitude also means restraint. Three things we deliberately did *not* build.
>
> An **AI immigration lawyer** — we will never call it that. It's a translator that knows when to refuse. Permanent.
>
> **Judge analytics** — predicting how a judge rules. The data exists, the math is easy, the harm is enormous. We will not ship it.
>
> **Real documents** — every screenshot, every video frame, every Devpost image is synthetic and watermarked. That line does not move."

**PLANTED:** *Have Backbone; Disagree and Commit* (saying no is harder than saying yes).

---

### Slide 11 — Roadmap (9:25 → 9:45)

**ON SLIDE:** Three small language icons (Korean · Hindi · Mandarin) and one large icon: *"Every frightening English letter."*

**SAY (~20 sec):** "Same trust stack, more languages — each one launches only when a native speaker on the team validates every output. And the same architecture handles utility shutoffs, school letters, IRS mail. Immigration is the launch vertical because that's where the fear is greatest."

**PLANTED:** *Think Big* (launch vertical, not the ceiling).

---

### Slide 12 — Close: gratitude (9:45 → 10:00)

**ON SLIDE:** Back to the wordmark + *Built with gratitude.* (Bookends Slide 1.)

**SAY (~15 sec):**
> "We built Carta Clara with gratitude — for the grandmothers who built our families, for the legal-aid clinics doing the real work, and for an AI humble enough to know which questions aren't its to answer. Thank you."

---

## The sneaky Leadership Principles cheat sheet

Judges in an Amazon hackathon listen for these. The deck **never prints the words "Leadership Principle"** — instead each one is planted as a natural phrase. This table is for the presenters only. Memorize the phrases; the LP lands on its own.

| Planted phrase (say this) | Leadership Principle (don't say this) | Where |
|---|---|---|
| "One 70-year-old woman holding a letter at 9pm" | Customer Obsession | Slides 2–3 |
| "Trust before features" / "The refusal is the feature" | Earn Trust | Slide 4, Demo |
| "Nothing stored past one hour" | Ownership | Slide 6 |
| "The trust is enforced by Bedrock, not by our prompt" | Earn Trust | Slide 7 |
| "One file, one command" | Invent and Simplify | Slide 8 |
| "Nothing orphaned, no surprise bill" / "$0.04 a scan" | Frugality | Slide 8 |
| "Here are the numbers" / 25-prompt eval suite | Insist on the Highest Standards · Are Right, A Lot | Slide 9 |
| "We considered. We didn't ship." | Have Backbone; Disagree and Commit | Slide 10 |
| "Immigration is the launch vertical" | Think Big | Slide 11 |
| "We built it in 36 hours and it deploys in one command" | Bias for Action | Slide 8 (if asked) |

Rule: if a judge says "which Leadership Principles did you use?", *then* you name them outright — and you'll have already demonstrated every one. That is the sneaky part: show first, name only on request.

---

## Pre-pitch checklist (do these before going on stage)

- [ ] Confirm the LanguagePickerView is live in the build and `Español` is the selection rehearsed on stage.
- [ ] Slide 9: replace target numbers with the **actual measured eval + latency numbers**.
- [ ] Print the synthetic NTA and the notario-scam SMS, both watermarked `DEMO – NOT A REAL CASE`.
- [ ] Pre-load the 90-second backup demo video in QuickTime.
- [ ] Test the projector HDMI adapter on the venue's actual cable.
- [ ] Confirm the Preparation Packet preview shows **no extension-request letter** (removed feature — see concerns below).
- [ ] Three timed dress rehearsals. The third is the one you perform.

---

## Backup plan (if something breaks on stage)

| Failure | Backup |
|---|---|
| Scan stalls > 40s | Cut to the 90-second video. Don't apologize — keep narrating. |
| Camera fails | Switch to the 90-second backup video. (The "Use the demo document" splash button has been removed — there is no in-app demo path anymore.) |
| Network drops | The 90-second video. Same narration. |
| Polly audio won't play | Skip the listen tap; the text card still shows. Move on. |
| Judge asks something you don't know | Pause. "Honest answer — I don't know. Here's how I'd find out: [method]." |

---

## Who does what on stage (3-person team)

- **Pitcher (Alex):** owns the words, the laptop, the slides. Center stage.
- **iOS lead:** holds the phone, taps the demo. Rehearse until you can do it without looking.
- **Backend lead:** holds the FAQ binder; steps in for deep technical questions (Bedrock, CloudFormation).

---

## Open concerns for Alex (decide before the pitch)

1. **Bedrock Guardrail ID is still `PLACEHOLDER`.** Refusals are prompt-enforced today, not Guardrail-enforced. The slide-7 talk track is honest about this; do not let yourself drift into "Guardrails enforces our refusals" on stage — that would overclaim. If a judge digs in, the honest answer is "the Guardrail is wired into the stack; the ID is `PLACEHOLDER` for the hackathon and the refusals are prompt-enforced today — flipping the ID is the immediate next step."
2. **Confirm `cachedPacket` pre-fetch is healthy.** The packet view should render instantly from the cache when "Help me respond" is tapped; if you ever see a spinner there, the pre-fetch failed and you're on the slow path. Rehearse the recovery: "the packet is generating now — while it does…" and keep narrating.

---

## Cross-references

- Up-to-date architecture + all diagrams: `docs/DIAGRAMS.md`, `docs/ARCHITECTURE.md`
- What ships / acceptance criteria: `docs/MVP.md`
- Bright lines: `docs/TENETS.md`
- Eval numbers: `docs/EVAL_PROMPTS_EXPECTED.md`
- Judge Q&A prep: `docs/FAQ.md`
- Superseded: `docs/PITCH_PLAN.md` (history only)

*Built for the current Carta Clara build. Last updated 2026-05-17.*
