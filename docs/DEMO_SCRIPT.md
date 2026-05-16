# Carta Clara — 3-Minute Demo Script

This is the beat-by-beat live demo. Memorize the **bold** sentences. The rest is direction.

**Total runtime:** 3:00 (leave 30s buffer for setup/intro)

**Driver:** You (Alex), iPhone in hand, laptop with slides projected.

**Backup:** 90-second pre-recorded video saved on laptop. If anything fails for >5 seconds live, switch to video and narrate over it.

---

## Pre-demo setup (do BEFORE you're on stage)

- [ ] iPhone connected via QuickTime screen-mirror to laptop
- [ ] iPhone airplane mode OFF, on hotspot (not venue wifi if at all avoidable)
- [ ] Carta Clara app open, on Splash screen, ready
- [ ] Synthetic NTA printed, watermarked DEMO, on the table in front of you
- [ ] Synthetic fake notario SMS text saved as a screenshot, ready to show
- [ ] Slides on slide 1 (the hook)
- [ ] Refusal counter visible in iPhone status bar area
- [ ] Backup video queued in QuickTime ready to play
- [ ] Two physical Response Preparation Packets printed (one as backup if you tear the first)

---

## 0:00 — 0:25 — Hook

**Stage direction:** Hold up the printed NTA in your right hand. Don't look at it. Look at the audience.

**Say (memorized):**

> **"This is the letter that paralyzes a family. The English is hard. The deadline is real. The wrong move costs everything. And the person reading it is usually a grandmother — translated by a 12-year-old at the kitchen table."**

**Pause 1 second. Lower the letter.**

> **"We did not build an AI immigration lawyer. We built a translator that knows when to stop."**

**LP woven (don't name it):** Customer Obsession — we started with a person, not a model.

---

## 0:25 — 0:55 — Scan + visible redaction

**Stage direction:** Pick up the iPhone with your other hand. Tap the camera button. Center the printed NTA in the viewfinder. Snap.

**Say while the redaction animation plays:**

> **"Before anything reaches the cloud, we redact. A-number, name, address, date of birth, case number. You're watching us do it now. The model never sees who she is."**

**Stage direction:** As the result cards load, swipe through the redaction confirmation. The cards appear:
1. Headline summary (Spanish)
2. Urgency card with hearing date
3. Section cards

**Tap the play button on the headline summary card.**

**Stage direction:** Polly speaks the Spanish summary aloud — 8 seconds of audio. **Stand still and let it play. Do not talk over it.**

**LP woven:** Earn Trust — the redaction is visible, not hidden in a privacy policy. Invent and Simplify — eight tabs collapsed into one snap.

---

## 0:55 — 1:25 — The refusal moment

**Stage direction:** Tap "Ask About This Document." The chat opens. The refusal counter is visible in the corner showing 0. **Type** (don't speak — typing makes it obvious to the audience):

```
Should I skip the hearing?
```

**Tap send.**

**Stage direction:** The refusal renders. The refusal counter ticks 0 → 1. A "Find legal help" card appears below it.

**Say while pointing at the screen:**

> **"There it is. The model refused. Not silently — visibly. And it didn't refuse and walk away. It told her where to find a free lawyer. Watch."**

**Tap the counter. The refusal log opens, showing 1 entry: "Legal strategy — routed to legal aid."**

> **"The first feature we built was the list of questions we refuse to answer. We tested 20 of them last night. 20 out of 20 refused. That's not an accident. That's the entire point of the product."**

**Close the refusal log.**

**LP woven:** Earn Trust + Insist on the Highest Standards. The refusal counter is the whole trust story compressed into one number.

---

## 1:25 — 2:00 — Scam / notario check

**Stage direction:** Swipe to the scam-check view. **Take out your phone again** and show a pre-loaded fake notario SMS (you saved this as a screenshot earlier):

> *"Pedro from Pedro Legal Services. We can fix your immigration papers fast — guaranteed result. Cash only $2,000. I know the judge personally. Pay today before you lose your case."*

**Hold the screenshot up to the camera in the Carta Clara app. Tap "Check this offer."**

**Stage direction:** The app processes for ~3 seconds. Returns a red-flag card listing 5 detected patterns:
- ❌ Guaranteed immigration result
- ❌ Cash-only payment
- ❌ "I know the judge"
- ❌ Pressure to pay quickly
- ❌ No mention of being a licensed attorney or DOJ-accredited representative

Each red flag has a citation chip: `FTC.gov: Immigration Services Scams` and `USCIS.gov: Avoid Scams`.

**Say:**

> **"These are not opinions. Each one is cited to the FTC and USCIS public advisories. We don't accuse anyone. We educate the user. Before paying anyone $2,000, check three things: are they a licensed attorney, are they a DOJ-accredited representative, and do they put their fees in writing?"**

**LP woven:** Dive Deep — we ground every flag to a real public source.

---

## 2:00 — 2:35 — Response Preparation Packet (the artifact moment)

**Stage direction:** Tap "Help Me Respond" at the bottom of the result screen. App generates the Preparation Packet — animated loading for ~4 seconds. The PDF preview renders.

**While loading, pick up the printed Preparation Packet from the table** (you printed it earlier so it's ready to physically hold). Hold it up.

**Say:**

> **"This is what we hand the grandmother. Not a response to USCIS — we will never write that. We are not lawyers and we never will be. This is what she brings to her free legal aid appointment. Translated summary of what's being asked. Evidence checklist. Pre-filled request to reschedule if she needs time. Phone-call script in Spanish for the legal aid intake line. And the questions to ask the lawyer who WILL write the response."**

**Stage direction:** Show the back of the packet, where the cover sheet reads in big text: **"Bring this to your appointment. Your lawyer will write the official response."**

> **"Translation gives you words. We give her a path to a lawyer."**

**LP woven:** Customer Obsession + Earn Trust. Plus the artifact is physical — it survives the demo.

---

## 2:35 — 2:55 — Architecture flash

**Stage direction:** Click to slide 4 (Architecture diagram). Don't explain the diagram — let the audience scan it.

**Say:**

> **"Six AWS services. Four of them are Bedrock — Knowledge Bases, Guardrails, multimodal Claude Sonnet 4.6, Polly for Spanish voice. One CloudFormation template deploys the whole trust stack. No custom models. No fine-tuning. The same architecture, tomorrow, runs tenant notices, utility shutoffs, school discipline letters, IRS mail — anywhere a frightening English document lands on a kitchen counter in America."**

**LP woven:** Frugality (managed services, no fine-tuning), Think Big (the trust stack scales beyond immigration), Bias for Action (CloudFormation = real engineering discipline).

---

## 2:55 — 3:00 — Close

**Stage direction:** Click to slide 6 (the close slide). Look at the audience. Pause one second.

**Say:**

> **"We built Carta Clara with gratitude — for the people who got us here, and for the moments AI should be careful, cited, and humble. Thank you."**

**Stage direction:** Stop talking. Smile. Wait for questions.

**LP woven:** Strive to be Earth's Best Employer + Success and Scale Bring Broad Responsibility. Without naming them.

---

## If something fails mid-demo

| Failure | Recovery |
|---------|----------|
| Camera snap doesn't focus | "Let me show you the pre-recorded version" → play backup video starting at 0:25 |
| Polly audio doesn't play | Skip it. "The voice was working in dress rehearsal — you can hear it in the Devpost video. Moving on." |
| Refusal counter doesn't increment visibly | Tap the counter manually to open the log. "Here's the refusal that just happened — logged." |
| Bedrock API throttles | "We've got a Nova Pro fallback for moments exactly like this." Swap models in app settings (build this toggle). Continue. |
| Wi-Fi cuts out | Switch to phone hotspot. If even that fails, play backup video. |
| App crashes | "Live coding, live risk. Let me show the backup." Play video. |

**The audience will forgive any failure if you handle it calmly.** What they won't forgive is panic. Practice the recovery lines in dress rehearsal Sunday morning.

---

## Q&A prep (after demo)

See `docs/FAQ.md` for the 8 most likely judge questions with rehearsed answers. Memorize the first sentence of each answer. The first sentence buys you 5 seconds to think about the rest.

---

## Dress rehearsal checklist (Sunday morning, run 3 times)

- [ ] Run 1: full speed, time yourself, identify any beat over 30s
- [ ] Run 2: full speed, in front of a teammate who plays "skeptical judge"
- [ ] Run 3: full speed, on the venue's actual stage if possible — projector, microphone, the whole setup

If Run 3 exposes a problem, fix it before lunch. Do not wing it on stage.

---

## Words to NEVER say during the demo

- "AI lawyer" / "AI legal advisor" / "legal AI"
- "We replace lawyers"
- "We're like ChatGPT but for immigration"
- "Disrupt"
- "Revolutionary"
- "Game-changing"
- "Solves immigration"

The product is humble by design. Sound humble. Earn trust by sounding earned.
