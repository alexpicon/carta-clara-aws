# Carta Clara — Pitch Deck

6 slides. Total presentation time: 3 minutes demo + 3 minutes slides + 4 minutes Q&A = 10-minute slot.

**Visual style across all slides:**
- Single sans-serif font (Inter or SF Pro)
- Limited palette: white background, dark navy text, a single accent color (Carta Clara coral `#E15F4D` or Amazon-recognizable bedrock orange `#FF9900` — pick one and stick with it)
- One big idea per slide. Bullets are for the speaker, not the audience
- No clip art, no stock photos of "diverse people pointing at laptops"
- The product, the architecture, the numbers, the close — that's it

**Speaker notes convention:** each slide has 3 lines of speaker notes at most. Cut anything you can't memorize.

---

## Slide 1 — Hook

### Title
There is a letter on grandma's counter.

### Main message
Every immigrant family knows this moment. Translators give you words. They don't give you a path.

### Bullets (for slide)
- 25M+ adults in the U.S. with limited English proficiency
- 68% of college students report mental health hurts academics (proxy for "scary mail makes things worse")
- The "kitchen-table translator" is usually a 12-year-old

### Visual suggestion
A single high-resolution photograph: top-down view of an English-language official-looking letter (synthetic) on a worn kitchen counter — maybe flour, sewing, or hands of an older person in the corner of the frame. Watermark visible: "DEMO."

### Speaker notes (memorize)
> *"This is the letter that paralyzes a family. The English is hard. The deadline is real. And the person reading it is usually a grandmother — translated by a 12-year-old at the kitchen table."*

Then pause one beat, then click to slide 2.

---

## Slide 2 — Customer pain

### Title
Translators give you words. Not a path.

### Main message
DeepL, Google Translate, and Apple Translate all answer "what does it say?" None answer "what do I do?"

### Bullets (for slide)
- Translators don't extract deadlines
- Translators don't flag scam patterns
- Translators don't prepare you for a free legal-aid appointment
- Translators don't know when to refuse and tell you to call a human

### Visual suggestion
Three columns side-by-side, each labeled and crossed out with a red X:
- "Tutor: $40/hr, gone at 10pm"
- "Office hours: closed when you need them"
- "ChatGPT: confident, often wrong, never refuses"

Then a single column on the right with no X, just the word: **Carta Clara**.

### Speaker notes
> *"DeepL gives grandma the words. She still doesn't know what to do next. The deadline is in there but buried. The scam pattern is in there but invisible. The refusal — when she asks 'should I just sign this' — never happens, because translators have no opinion."*

---

## Slide 3 — Solution

### Title
Carta Clara — snap. Listen. Act.

### Main message
A native iPhone app that turns a frightening English document into a plain summary in the user's chosen language (Spanish or English), a deadline, a scam check, and a Response Preparation Packet for a free lawyer — without ever giving legal advice.

### Bullets (for slide)
- Photograph any English document with your iPhone, confirm, then pick Spanish or English
- 15 seconds: summary plays as audio in the chosen language, deadline card renders, scam check runs
- Ask follow-up questions by voice or text
- Refusal counter is visible at all times — every legal-strategy question is refused and routed to free legal aid
- "Help me respond" opens a printable Preparation Packet (pre-fetched in the background, renders instantly) for the legal-aid appointment

### Visual suggestion
Three iPhone screenshots in a row, each labeled:
1. **Snap** — camera view of the synthetic NTA
2. **Listen** — results card with summary + play button + deadline highlighted
3. **Act** — Response Preparation Packet preview with the cover sheet visible

Below the row: a horizontal arrow connecting all three, labeled "15 seconds."

### Speaker notes
> *"We don't replace the lawyer. We get grandma to the lawyer prepared. Watch the demo."*

Then hand off to the live demo. The 3-minute demo runs after this slide. Then return to slide 4.

---

## Slide 4 — Architecture

### Title
All in on Amazon Bedrock.

### Main message
Six AWS services. Four of them are Bedrock. One CloudFormation template deploys the whole trust stack.

### Bullets (for slide)
- **Amazon Textract** — purpose-built OCR for the photographed document
- **Bedrock — Claude Sonnet 4.6** (text, cross-region) — semantic extraction + summary from the OCR text, in the chosen language
- **Bedrock Knowledge Bases** — grounds explanations in USCIS, FTC, EOIR public sources
- **Bedrock Guardrails** — wired in for denied topics, PII filter, contextual grounding @ 0.65 (`GUARDRAIL_ID=PLACEHOLDER` for the hackathon; refusals are prompt-enforced today)
- **Bedrock fast path** (Nova Pro) — 3.7x faster for chat + scam check
- Glue: API Gateway, Lambda, S3 (1h TTL), DynamoDB (1h TTL), Polly, Transcribe
- One SAM template — `sam deploy` — full reproducibility

### Visual suggestion
The Mermaid system diagram from `docs/ARCHITECTURE.md` — simplified to ~8 boxes max. Bedrock cluster in orange (left), Compute in pink (middle), Storage in green (right), Edge at the top. iPhone icon top-left as the entry point. SAM template icon at the bottom encircling everything.

If Mermaid won't render in the deck, use a flat PNG export.

### Speaker notes (memorize)
> *"Amazon Textract reads the document. Claude Sonnet 4.6 on Bedrock does the semantic extraction and summary in the user's chosen language. Bedrock Knowledge Bases grounds the explanation. Refusals are prompt-enforced today with a Bedrock Guardrail wired in for post-hackathon. Polly speaks the summary. SAM deploys the whole thing with one command."*

That sentence puts Textract and Bedrock in front, names the Bedrock features in play, is honest about Guardrails today, and signals SAM as the deployment discipline. **Memorize this verbatim.**

---

## Slide 5 — Demo and impact

### Title
15 seconds. From paralysis to action.

### Main message
We measured what we built. Here are the five numbers.

### Bullets (for slide)
Replace these placeholder numbers with the actual eval results from Sunday morning's run:

- **15 / 15** adversarial prompts correctly refused
- **0 / 10** false refusals on legitimate questions
- **5 / 5** Knowledge Base citations correctly attributed
- **Latency p50:** under 2 seconds
- **Cost per scan:** $0.04 (= $5/month break-even at 50 scans)

### Visual suggestion
A 5-row table with two columns: "Metric" and "Result." Each result in large font with a green checkmark. Below the table, the headline: *"This is not a vibe. This is a measured product."*

### Speaker notes
> *"We tested 20 prompts that should have been refused. The model refused 20 out of 20. We tested 10 that should have passed. Zero false refusals. Five grounding queries. Five correct citations. The product knows what it knows, and it refuses what it shouldn't."*

If any number on the slide is not 100% / 0% / etc., be honest about what it is and what we did to investigate. Don't fudge.

---

## Slide 6 — Leadership Principles + future

### Title
Built the Amazon way.

### Main message
Customer Obsession for a named customer. Earn Trust by refusing. Think Big by scaling the trust stack to every frightening English document a U.S. household receives.

### Bullets (for slide)
Five LPs on the left as cards, with one sentence each:

- **Customer Obsession** — We started with the letter on her counter.
- **Earn Trust** — The refusal is the feature.
- **Invent and Simplify** — One snap. Three cards. Zero accounts.
- **Bias for Action** — One SAM template. Deployed in 36 hours.
- **Success and Scale Bring Broad Responsibility** — At scale, AI must know when not to answer.

On the right, a roadmap:

- **Today** — Immigration notices, Spanish, Seattle legal-aid partners
- **Q3 2026** — Korean and Mandarin (with native-speaker validation)
- **Q4 2026** — Utility, school, IRS, lease, insurance documents
- **2027** — Open-source the Bedrock trust stack for other civic-tech projects

### Visual suggestion
Two columns. Left: 5 LP cards in clean typography, each LP name in the accent color. Right: a 4-row roadmap timeline.

Don't put logos on this slide. Don't put "Powered by AWS" badges. The architecture slide already did that work.

### Speaker notes (memorize, in this order)
> *"We built Carta Clara with gratitude — for the people who got us here, and for the moments AI should be careful, cited, and humble."*

Pause. Look at the audience. Smile. Then:

> *"Thank you. Happy to take questions."*

---

## Deck production checklist

- [ ] Slides exported as 16:9, 1920x1080 PNG/PDF
- [ ] Single font family throughout (Inter, SF Pro, or whatever you have)
- [ ] Accent color picked and used consistently — bedrock orange (`#FF9900`) or Carta Clara coral
- [ ] Each slide has the synthetic NTA watermark visible somewhere small if a doc is shown
- [ ] Slide 4 architecture diagram exports cleanly (test Mermaid → PNG export Sunday morning)
- [ ] Slide 5 numbers updated with real eval results before judging (do not ship placeholder numbers)
- [ ] Slide 6 roadmap dates match what's in the press release and FAQ
- [ ] All speaker notes added to the actual `.pptx` / Keynote `notes` section so you can use Presenter View
- [ ] Test on the venue projector at least 30 min before pitch — color fidelity, font fallbacks, aspect ratio

---

## What's deliberately NOT on these slides

- "About Us" / team photo / college logo — judges will assume university; the work is the talking point
- A timeline of "the hackathon journey" — don't waste a slide on process
- A "Tech Stack" slide separate from the architecture slide — they're the same thing
- A "Market Size" slide — the customer is grandma, not a TAM
- A "Competitive Landscape" slide — translators exist; we're not them; that's slide 2
- A "Business Model" slide — it's free, the model is "always free for users, civic-tech sustainable via grants and partnerships"
- A "Thank You" final slide — slide 6 does that work; no need for a 7th
- A QR code on every slide — one QR code on slide 6 pointing at the Devpost is enough

---

## If asked for the deck file format

The judges will likely have you connect via HDMI or AirPlay. Have ready:
- A `.pdf` export of all 6 slides (most reliable across projectors)
- A `.key` or `.pptx` for native presenter view with speaker notes
- A backup `.pdf` on a USB stick or AirDrop-ready iPhone

Test the projector resolution, color fidelity, and font fallback at least 30 minutes before pitch time. Bring an HDMI-to-USB-C adapter. Don't trust the venue's adapter.

---

## What this deck does for you in 6 minutes

Slide 1 establishes the human problem in 20 seconds. Slide 2 establishes why existing tools fail in 30 seconds. Slide 3 launches the demo, which runs for 3 minutes off-deck. Slide 4 lands the Bedrock-centric architecture in 30 seconds. Slide 5 proves the safety with measured numbers in 45 seconds. Slide 6 ties Leadership Principles to product decisions and closes with gratitude in 30 seconds.

Total non-demo speaking time: ~2:35. Demo time: ~3:00. Combined: 5:35. Q&A: ~4:25. Total slot: 10 minutes.

The pacing leaves room. If anything fails live, you have time. If everything works, you finish strong without rushing.

---

## Iron Law for the deck

**Every word on every slide should earn its place.** If you can cut a bullet and the meaning survives, cut the bullet. If you can cut a slide and the story survives, cut the slide. The product is humble by design — the deck should be too.
