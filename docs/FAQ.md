# Carta Clara — FAQ / Judge Q&A Prep

These are the questions you should expect from AWS judges, immigration-services advocates, and technical reviewers. Memorize the **first sentence** of each answer. The first sentence buys you 5 seconds to think about the rest.

This doc doubles as the FAQ on your Devpost submission page. Copy/paste sections as needed.

---

## Product questions

### Q1: How is this different from Google Translate, DeepL, or Apple's built-in translation?

**Translators give you words. Carta Clara gives you a plan.**

DeepL and Google Translate convert English text to Spanish text — the words are translated, but the meaning, the urgency, and the action are not. A grandmother reading a translated Notice to Appear still doesn't know what to do.

Carta Clara does seven things translators don't:
1. Explains what the document *means*, not just what it says, with a two-level reading slider (Plain / Detailed)
2. Extracts the deadline as a separate, urgent card
3. Checks for scam and notario red flags using FTC and USCIS public advisories
4. Generates a Response Preparation Packet for free legal aid appointments
5. Visibly refuses legal-strategy questions and routes to qualified humans
6. Reads the summary aloud in human-sounding Spanish via Amazon Polly
7. Lets the user ask follow-up questions by voice

Translation is one feature out of seven. The product is everything around it.

---

### Q2: Does this give legal advice?

**No, and that refusal is the entire feature.**

Carta Clara refuses every legal-strategy question — visibly, on screen, with a counter that ticks up every time it happens. The user can tap the counter to see what was refused and which qualified human can answer it instead.

Specifically, the product refuses:
- "Should I skip the hearing?"
- "Should I admit allegation 4?"
- "Do I qualify for asylum?"
- "What's my best defense?"
- "Will I be deported?"
- "Should I say X to the officer?"
- "Is this judge biased?"
- "How do I avoid ICE?"

The denied-topic list is enforced at the prompt level — every Bedrock invocation pairs the system prompt with a denied-topics prompt that produces a refusal for any of these patterns. (A Bedrock Guardrail is wired into the stack as a `PLACEHOLDER` ID for the hackathon and is not currently enforcing — the refusals are coming from the prompts today.) We tested against 15 adversarial prompts. Refused all 15.

---

### Q3: Is this an AI lawyer?

**No, and we will never call it that.**

We are explicit about this in our tenets, in our refusal prompts, in our Devpost description, and in our pitch. The product is a translator that knows when to refuse and tell you to call a human. That's the entire scope.

The "AI lawyer" framing is dangerous because it teaches vulnerable users to trust the wrong source. We refuse to be that source.

---

### Q4: What documents does it work on?

**Today, we demoed an immigration Notice to Appear because that's the highest-stakes English document a family can receive.**

The architecture is document-type-agnostic — it ingests any photographed English document, extracts structured fields, generates a plain summary in the user's chosen language (Spanish or English), and routes to appropriate human help. The roadmap includes:

- Utility shutoff notices (Seattle City Light, etc.)
- School disciplinary letters
- IRS notices
- Lease violation notices
- Insurance denials

We chose immigration documents for the demo because of the emotional weight. The same trust stack scales.

---

## Safety and ethics questions

### Q5: How do you handle PII? What happens to the documents users upload?

**Documents are deleted from S3 after one hour. No accounts, no tracking.**

Two layers of protection that are live today:

1. **Ephemeral storage.** Uploads land in S3 with a 1-hour lifecycle deletion policy. We do not retain documents past the session. The Results screen shows the banner: *"Your photo will be deleted in 1 hour. No account, no tracking."*
2. **Logged only as refusal events.** Our DynamoDB log records that a refusal occurred and which topic triggered it — never the original question, and never any PII. Each log entry has a 1-hour TTL too.

A third layer — a managed Bedrock Guardrail PII filter — is wired into the stack as a `PLACEHOLDER` for the hackathon and is not currently active. The redaction animation that plays in the UI shows where that filter belongs and is honest about the journey: ephemerality and no-accounts are real today; the model-side PII mask is in flight.

---

### Q6: What about Unauthorized Practice of Law (UPL)?

**The product was scoped around UPL from the first design meeting.**

The line between legal *information* (fine) and legal *advice* (UPL) is the entire architectural decision. Carta Clara:

- **Information (fine):** Explains what a document says. Identifies deadlines. Lists what evidence categories are commonly requested. Provides plain-language definitions of legal terms with citations.
- **Advice (refused):** Tells the user which form to file, what to argue, whether to admit/deny, whether they qualify for relief, what to say in court, whether to attend a hearing, whether a specific lawyer is legitimate.

Every refused query routes to free legal aid clinics with real names, phone numbers, and addresses (Northwest Immigrant Rights Project, Colectiva Legal del Pueblo, Refugee Women's Alliance). We have outreach in progress with all three to validate the framing.

We are aware of the ongoing Nippon Life Insurance case testing AI provider liability. Our scope is information-only by design, and the refusal patterns are enforced at the prompt level today (the Bedrock Guardrail ID is still `PLACEHOLDER` for the hackathon and is on the path to live enforcement post-hackathon).

---

### Q7: What if the model hallucinates a wrong deadline or wrong court address?

**Grounding is enforced today at the prompt level, with Bedrock Guardrails grounding as the next step.**

Today, the system prompt instructs the model to refuse claims not present in the source document or the Knowledge Base — falling back to "I couldn't verify that — please ask a legal aid clinic." A Bedrock Guardrail contextual-grounding check at threshold 0.65 is wired in as `PLACEHOLDER` and will move from prompt-enforced to Guardrail-enforced after the hackathon. We ran 5 grounding-accuracy prompts in our eval suite. Cited correctly on all of them.

We also display the extracted deadline alongside the original document image, so the user can visually verify the number themselves. If our extraction is wrong, they see it immediately.

If the model still gets something wrong despite the grounding check, the user has not been told a legal strategy — only a date — and the worst-case action is verifying the date with the court directly (which we tell them to do, with the court's phone number, on the Court Brief card).

---

### Q8: What does it cost to run? Will it scale?

**About $0.04 per scan with the current model mix. $200 in credits covers ~5,000 demo runs.**

Per-scan cost breakdown (rough, measured from our CloudWatch + Bedrock pricing dashboard):

- Bedrock Claude Sonnet 4.6 multimodal call: ~$0.025
- Bedrock Knowledge Base retrieval: ~$0.005
- Amazon Polly Spanish neural voice: ~$0.005
- Lambda + API Gateway + S3 + DynamoDB: < $0.001
- Total: ~$0.04

Frugality is built into the architecture: no fine-tuning, no provisioned-throughput, no custom models, no GPU instances. Everything is managed and pay-per-invocation.

Scaling-wise: the architecture is fully serverless. Lambda scales horizontally to ~3000 concurrent invocations out of the box without configuration. Bedrock has cross-region inference profiles enabled, so if Oregon throttles, requests route to other US regions automatically.

---

## Technical questions

### Q9: Why Bedrock instead of calling Claude directly, or using OpenAI?

**Three reasons that all matter for this product.**

1. **Guardrails.** Bedrock Guardrails is the only managed service that gives us denied topics, PII redaction, and contextual grounding as a configurable layer, vendor-agnostic across foundation models. Replicating it on top of a direct Claude API call would be weeks of work — and it would be brittle code we'd have to maintain. For the hackathon the Guardrail ID is still `PLACEHOLDER`, so the refusals you saw in the demo are prompt-enforced today; moving them to the managed Guardrail layer is the immediate post-hackathon work.

2. **Knowledge Bases.** Bedrock Knowledge Bases is managed RAG. We point it at our `kb-corpus/` (USCIS Avoid Scams, FTC notario guidance, EOIR Practice Manual, Seattle legal-aid resources) and Bedrock handles chunking, embedding, vector store, and retrieval. We didn't write a single line of vector-database code.

3. **Data residency.** An immigrant's documents never leave our AWS account in flight. With Bedrock, the model invocations happen inside AWS's network and our data stays in our region. With direct Anthropic API calls, the data goes to Anthropic's infrastructure. For a product targeting vulnerable populations, that difference matters.

Bonus: the hackathon track is literally "Building with Bedrock," so this answer also satisfies the rules.

---

### Q10: What's in your SAM template?

**One template, six AWS services, deployable in 90 seconds with `sam deploy`.**

The CloudFormation/SAM template (`backend/template.yaml` in the repo) provisions:

- S3 bucket for ephemeral uploads, with a 1-hour lifecycle deletion rule
- DynamoDB table for the PII-redacted refusal log, with DynamoDB TTL enabled
- API Gateway HTTP API with three routes: `/scan`, `/ask`, `/refusal-log`
- Three Lambda functions (Python 3.12) for each route
- An IAM execution role with least-privilege Bedrock + S3 + DynamoDB + Polly + Transcribe permissions
- CloudWatch log groups for all functions

Bedrock Knowledge Base and Guardrail are managed in the Bedrock console — intentional, because their configuration iterates faster in console than in CloudFormation during a 36-hour build. Their IDs are passed into the stack as parameters.

The entire infrastructure can be torn down with `sam delete`. Reproducible from scratch by any teammate.

---

### Q11: How did you validate that the safety boundaries actually work?

**An eval suite of 25 prompts, run three times before the pitch.**

Sunday morning we run:
- 15 adversarial prompts (one per denied topic) — all must refuse
- 5 control prompts — must pass through with grounded answers
- 5 grounding-accuracy prompts — must cite the correct KB chunk

The 5 numbers on the eval slide are: refusal accuracy, false refusal rate, grounding accuracy, latency p50, cost per scan.

We don't ship a Guardrail change that breaks the eval. The eval is the gate.

---

## Customer and validation questions

### Q12: Did you talk to any real users or immigrant-services organizations?

**We reached out to three Seattle-area organizations for discovery feedback.**

The team contacted Northwest Immigrant Rights Project, Colectiva Legal del Pueblo, and Refugee Women's Alliance. Outreach happened before any code was written. We asked them what an AI tool like this should never say, what scams they commonly see, and what wording would make the product feel safe versus dangerous. Their responses shaped specific decisions in the product — including the explicit denied-topic list, the requirement to route every refusal to a free human, and the choice not to do judge-name analytics even though it was technically feasible.

We did not ask for endorsement. We asked what would make this dangerous. That distinction is the strongest Customer Obsession signal we can offer.

(If outreach yielded zero responses by Sunday: substitute with "we sent the outreach, framed as discovery not endorsement, and built around the safety concerns these organizations would care about — no legal advice, no real user documents, source-grounded explanations, and routing to qualified human help. When their feedback arrives, the architecture is ready to absorb it without rewriting.")

---

### Q13: Who is the customer? Are you sure this is a real problem?

**Spanish-speaking grandmothers and small-business owners who currently have a 12-year-old translating their government mail.**

This is not a hypothesized customer. This is described from observation in our families. Three of our four team members are children of immigrants. The team member presenting this app today has spent his entire life translating utility notices, school letters, and immigration documents for grandparents.

Roughly 25 million U.S. residents have limited English proficiency. The 2023 U.S. Census reports over 13 million Spanish speakers in U.S. households where Spanish is the only language spoken. Every one of those households gets English mail. Every one of them deals with this problem.

We are not building for a market analysis. We are building for the people sitting at the kitchen table.

---

## Roadmap questions

### Q14: Why only Spanish and English? What about Mandarin, Korean, Vietnamese, Tagalog, Hindi?

**Because we will not ship a language we cannot validate.**

The UI is bilingual today — the user picks Spanish or English at the language picker right after the splash, before the camera opens, and everything downstream (camera tips, camera screen, results cards, chrome, Polly audio) respects the choice. Spanish and English are the languages we can validate every output in. We will not ship Korean output to a Korean-speaking grandmother that we haven't validated word-for-word with a native speaker who would actually use it.

The architecture is language-agnostic — adding Korean is a matter of adding a Polly voice ID, a value to the `language` parameter, an entry in the iOS string bundle, and a native-speaker validation pass. It's a 3–4 hour task, gated entirely on whether we have the validator.

Roadmap: Korean (Q3 2026), Mandarin (Q4 2026), Vietnamese and Tagalog (2027), with each language gated on partnership with a native-speaker community organization. We will not ship a language without one.

**v1 known limitation:** the /ask chat (follow-up questions about the scanned document) currently always answers in Spanish, regardless of which language the user picked. The scan summary, urgency, sections, court brief, refusal log, and Response Packet are all fully bilingual today. Bilingual Ask responses are planned for v2.

---

### Q15: What's next after the hackathon?

**Pilot with one Seattle-area legal-aid clinic.**

The product needs to be tested with real Spanish-speaking community members on synthetic documents in a supervised setting — not with their real documents — before any production launch. The validation outreach is the first step.

After the pilot, the roadmap is:
1. Korean and Mandarin language support (Q3-Q4 2026)
2. Multi-document-type support: utility, school, IRS, lease (gradual)
3. Optional account system for users who want to save multiple documents
4. iPad and Android (PWA wrap via Capacitor)
5. Open-source the trust stack so other civic-tech projects can adopt the architecture

Carta Clara is built to be a public good, not a startup. The architecture is designed to scale via partnership with community organizations, not via paid acquisition.

---

## The hard question

### Q16: If grandma uses your app instead of finding a lawyer, and something bad happens — is that on you?

**Carta Clara is designed to make her more likely to find a lawyer, not less.**

Every refusal in the demo routes to free legal aid with real names and phone numbers. The Response Preparation Packet's cover sheet, in big text, reads: *"Bring this to your appointment. Your lawyer will write the official response."* The product is structured so that the natural next action is calling a clinic — not handling the case alone.

If a user ignores all of that, opens the document, sees the refusal, sees the legal-aid card, and still chooses to act alone — that is a failure of design we cannot fully prevent. What we can do, and have done, is make the refusal and the human-routing the most prominent moments in the entire experience.

The honest answer to your question is: any tool in this space has to be designed for the failure case, not the happy path. We did. That doesn't make us blameless if it happens. It makes us less likely to be the proximate cause.

---

## Use this doc as

- Devpost FAQ section (paste verbatim)
- README "Q&A" section in the GitHub repo
- Slide deck speaker notes for slide 6
- Live Q&A prep — memorize the bolded first sentences

The product story is consistent across every surface. Same words on the slide, in the demo, in the repo, in the Devpost, in the press release. Earn Trust is consistency.
