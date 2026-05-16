# Bedrock Guardrails Configuration

This document is the paste-ready config for creating the `carta-clara-guard` Guardrail in the AWS Bedrock console.

**Region:** us-west-2 (must match the SAM-deployed Lambdas)

**Guardrail name:** `carta-clara-guard`

**Description:** Refuses legal, tax, and medical strategy questions. Masks PII before model invocation. Enforces contextual grounding so the model cannot invent details not present in the source document or knowledge base.

---

## Section 1 — Denied Topics

Create each of the 10 denied topics below in the console. For each, paste the **Name**, **Description**, and 3–5 **Sample phrases**. The console will use these to train the topic-classification layer.

---

### Topic 1: Legal Strategy

**Name:** `LegalStrategy`

**Description:** The user is asking the model to recommend a legal approach, choose between legal options, decide what to argue, or strategize about their immigration, civil, criminal, or administrative case. This is the practice of law and may only be performed by a qualified attorney or accredited representative.

**Sample phrases:**
- What should I argue in court?
- Should I claim asylum or cancellation of removal?
- How do I beat this charge?
- What's my best defense?
- Should I appeal this decision?
- Which form should I file?
- Should I sue?

---

### Topic 2: Hearing Attendance Decisions

**Name:** `HearingAttendance`

**Description:** The user is asking whether to attend a court hearing, skip a hearing, reschedule a hearing without a documented conflict, or otherwise decide on procedural attendance matters. Missing immigration hearings has severe consequences. Only a qualified legal professional should advise on this.

**Sample phrases:**
- Should I skip my hearing?
- Should I go to court?
- Can I just not show up?
- Is it okay to miss this date?
- Should I attend or run?

---

### Topic 3: Admit or Deny Allegations

**Name:** `AdmitDenyAllegations`

**Description:** The user is asking whether to admit, deny, or contest specific allegations in an immigration notice, court filing, or government document. Pleading decisions are core legal strategy and must be made with a qualified attorney.

**Sample phrases:**
- Should I admit allegation 4?
- Can I deny everything?
- What if I just say it's all true?
- Should I contest this charge?

---

### Topic 4: Eligibility Predictions

**Name:** `EligibilityPredictions`

**Description:** The user is asking whether they qualify for asylum, cancellation of removal, adjustment of status, withholding, U-visa, T-visa, or any other form of immigration relief. Eligibility determinations are legal opinions that may only be issued by a qualified attorney or accredited representative.

**Sample phrases:**
- Do I qualify for asylum?
- Am I eligible for a green card?
- Can I get a U-visa?
- Will I be approved?
- Am I eligible for cancellation?

---

### Topic 5: Outcome Predictions

**Name:** `OutcomePredictions`

**Description:** The user is asking the model to predict the outcome of their case, including whether they will be deported, granted relief, win an appeal, or face specific consequences. Case outcomes depend on facts, law, evidence, representation, and many factors the model cannot evaluate.

**Sample phrases:**
- Will I be deported?
- Will I win my case?
- What are my chances?
- How will the judge rule?
- Am I going to lose?

---

### Topic 6: Judge Bias Claims

**Name:** `JudgeBiasClaims`

**Description:** The user is asking the model to characterize an immigration judge as biased, harsh, lenient, racist, or otherwise. Statistical patterns in published data do not establish bias in any individual case. The model must not characterize judges.

**Sample phrases:**
- Is this judge biased?
- Is this judge racist?
- Is this judge tough on Mexicans?
- Will this judge deny me because of my country?
- What's this judge's denial rate?

---

### Topic 7: Law Enforcement Interaction Scripts

**Name:** `LawEnforcementScripts`

**Description:** The user is asking what to say to ICE officers, DHS officials, immigration judges, police, or other law enforcement. Scripted answers to law enforcement can constitute legal strategy and put the user at serious risk.

**Sample phrases:**
- What should I say to ICE?
- What do I tell the officer if they ask?
- How do I answer the judge?
- What should I say if they detain me?
- What's the right thing to tell DHS?

---

### Topic 8: Evasion and Avoidance Instructions

**Name:** `EvasionInstructions`

**Description:** The user is asking how to evade law enforcement, hide their location, avoid detection, flee, or otherwise circumvent legal process. The model must never provide such instructions.

**Sample phrases:**
- How do I hide from ICE?
- Where can I go so they won't find me?
- How do I disappear?
- Can I leave the country and come back?
- How do I avoid being deported?

---

### Topic 9: Medical, Tax, or Financial Advice

**Name:** `OtherProfessionalAdvice`

**Description:** The user is asking the model to recommend medical treatment, tax filing strategy, investment decisions, or other professional advice that requires a licensed practitioner. The product is scoped to civic document understanding only.

**Sample phrases:**
- Should I pay this tax bill?
- Is this medication safe?
- Should I invest in this?
- What dose should I take?
- How do I file my taxes?

---

### Topic 10: Document Authenticity Determinations

**Name:** `DocumentAuthenticity`

**Description:** The user is asking whether a specific document, lawyer, notario, or legal service provider is fraudulent or legitimate. The model can flag red-flag patterns commonly associated with scams (educational) but must not state with certainty that any specific person or document is fraudulent.

**Sample phrases:**
- Is this person a real lawyer?
- Is this notario legit?
- Is this document fake?
- Is this a scam?
- Can I trust this office?

---

## Section 2 — Safe Replacement Text (per topic)

When Guardrails blocks a query under a denied topic, the model returns this replacement text in the user's language. Configure these in the **Messaging** section of each denied topic.

**Default refusal pattern (English):**

> I can't help with legal strategy. I can explain the document you uploaded, summarize what it says, identify deadlines, and help you prepare questions for a qualified immigration attorney. For your specific question, please contact a free legal aid clinic — they can answer it safely and confidentially.

**Default refusal pattern (Spanish):**

> No puedo ayudarte con estrategia legal. Sí puedo explicarte el documento que subiste, resumir lo que dice, identificar fechas importantes y ayudarte a preparar preguntas para un abogado de inmigración. Para tu pregunta específica, por favor contacta un servicio de ayuda legal gratis — ellos pueden responder de manera segura y confidencial.

**Always include after the refusal (both languages):**

> [Card: Find legal help → tap to see nearby free legal aid clinics]

---

## Section 3 — PII Filter (Sensitive Information Filters)

Configure the following PII types in the Guardrail's PII filter:

| PII Type | Action | Why |
|----------|--------|-----|
| `NAME` | Anonymize | The model should never echo a user's full name back |
| `EMAIL` | Block | We don't need email; collecting it via prompt is unsafe |
| `PHONE` | Anonymize | Mask before storage |
| `ADDRESS` | Anonymize | Mask before storage |
| `US_SSN` | Block | Should never appear in our use case; block as defensive |
| `IP_ADDRESS` | Block | Defensive |
| `DRIVER_ID` | Anonymize | Sometimes in immigration docs |
| `CREDIT_DEBIT_CARD_NUMBER` | Block | Should never appear |
| `DATE_OF_BIRTH` | Anonymize | Mask before storage |

**Custom regex PII patterns** to add (these are immigration-specific and not built-in):

| Pattern Name | Regex | Action |
|--------------|-------|--------|
| `A_NUMBER` | `A[\s-]?\d{3}[\s-]?\d{3}[\s-]?\d{3}` | Anonymize → `[REDACTED_A_NUMBER]` |
| `USCIS_RECEIPT` | `(WAC|EAC|LIN|SRC|NBC|MSC|YSC|IOE)\d{10}` | Anonymize → `[REDACTED_RECEIPT_NUMBER]` |
| `CASE_NUMBER` | `\b\d{3}[-\s]?\d{4}[-\s]?\d{4}\b` | Anonymize → `[REDACTED_CASE_NUMBER]` |

---

## Section 4 — Contextual Grounding

Enable contextual grounding with these thresholds:

| Check | Threshold | Action on violation |
|-------|-----------|---------------------|
| **Grounding** (response is supported by source) | 0.65 | Block + return "I couldn't verify that in your document. Please ask a legal aid clinic." |
| **Relevance** (response addresses the user's question) | 0.50 | Block + return generic clarification request |

**Why 0.65 grounding and not 0.85:** Stricter thresholds (0.85+) cause too many false refusals on legitimate translation queries during demos. Tune up after Sunday if production-bound. For hackathon, 0.65 catches the obvious hallucinations without blocking the demo flow.

**Source for grounding:** The Knowledge Base (`carta-clara-kb`) plus the document the user just uploaded. Both are passed as `grounding_source` in the API call.

---

## Section 5 — Content Filters (Standard)

These are the AWS-provided content filters. Set all to **High**:

| Filter | Input strength | Output strength |
|--------|----------------|-----------------|
| Hate | High | High |
| Insults | High | High |
| Sexual | High | High |
| Violence | High | High |
| Misconduct | High | High |
| Prompt attack | High | N/A |

For our use case there's no scenario where these should fire on legitimate user input. If they fire, something is being injected — refuse.

---

## Section 6 — Word Filters

Add these as managed word filters (Block on input):

- Profanity → use AWS's built-in profanity filter set
- Custom blocks (add manually): none for v1

---

## Section 7 — How to apply this Guardrail

Once created in the console, the Guardrail will have an ID like `abcd12345` and a version (start with `DRAFT`, publish to `1` after testing).

Update the SAM stack with the IDs:

```bash
cd /Users/alexnpc/Hackathon/carta-clara/backend
sam deploy \
  --parameter-overrides \
    GuardrailId=<YOUR_GUARDRAIL_ID> \
    GuardrailVersion=DRAFT
```

In Lambda code, attach the Guardrail to every Bedrock invocation:

```python
response = bedrock.invoke_model(
    modelId=os.environ["MULTIMODAL_MODEL_ID"],
    guardrailIdentifier=os.environ["GUARDRAIL_ID"],
    guardrailVersion=os.environ["GUARDRAIL_VERSION"],
    body=json.dumps({...}),
)
```

When a denied topic is triggered, the response body contains a `stopReason: "guardrail_intervened"` and the safe-replacement text. The Lambda should:

1. Detect the intervention
2. Write a refusal log entry to DynamoDB (PII-redacted, only the topic name + timestamp)
3. Return the safe-replacement text to the iOS app
4. Trigger the refusal counter increment in the UI

---

## Section 8 — Eval after configuration

After the Guardrail is created and the SAM stack is updated:

1. Run all 20 prompts from `docs/EVAL_PROMPTS.md`
2. Confirm the 15 adversarial prompts all return `guardrail_intervened`
3. Confirm the 5 control prompts all pass through and get sensible answers
4. If any adversarial prompt slips through: tighten the corresponding denied topic's description or add more sample phrases
5. If any control prompt is wrongly refused: relax the corresponding topic or lower the grounding threshold

Record results in a row of `docs/EVAL_PROMPTS.md` under "Run 1," "Run 2," etc.

---

## Bright line that never moves

These Guardrails exist because the alternative — a model that gives plausible-sounding legal advice to a scared grandmother — is the kind of failure that ruins lives. The refusal IS the feature. Tune thresholds when needed, but never remove a denied topic for the sake of a smoother demo.
