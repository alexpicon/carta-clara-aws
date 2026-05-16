# Carta Clara — Press Release (Working Backwards)

**FOR IMMEDIATE RELEASE**

---

## **The Letter on Grandma's Counter Is No Longer a Crisis**

*Carta Clara is a free iPhone app that turns frightening English mail into a plain-Spanish summary, a deadline, a scam check, and a Response Preparation Packet for a free lawyer — in under 30 seconds, without ever giving legal advice.*

---

Every immigrant family knows the moment: an official-looking letter arrives in English, the household stops, and a child is handed a phone to translate something a child should never have to translate alone. The letter could be a school notice, a utility shutoff, an IRS form, or — worst — an immigration notice. Translation tools convert the words. They don't convert the fear.

**Carta Clara** is a free iPhone app that does. Photograph any English document, and within 30 seconds the app shows you, in your language, what the document says, what's urgent, what scams to watch for, and what to bring to a free legal-aid appointment. Everything is cited. Nothing is invented. And whenever a question crosses into legal strategy — *"should I skip my hearing?", "should I sign this?", "will I be deported?"* — the app refuses. Gently. Visibly. And points to a real human lawyer who can answer it for free.

"We built Carta Clara because of the grandmothers we grew up with," said Alexander Picón, founder of Carta Clara and a student at Seattle University. "My grandmother is brilliant, fluent, and dignified — in Spanish. When an English document arrives, she becomes someone else. Smaller. Quieter. Asking children to translate. The translators that exist already give her words. She doesn't need words. She needs to know what's urgent, what to do next, and when to call a human she can trust. So we built that."

**How it works.** The user opens the app and photographs the document with their iPhone's camera. Carta Clara visibly redacts every piece of sensitive information — A-number, name, address, date of birth, case number — before sending anything to a cloud model. Then it returns:

- **A headline summary** in plain Spanish, with audio playback in a human-sounding voice
- **A deadline card** showing what's urgent and when
- **Expandable section cards** for each part of the document, with a reading-level slider so the user can choose between 5th-grade and full-detail explanations
- **A scam / notario red-flag check** that scans for the warning signs the FTC and USCIS publish — guaranteed results, cash-only payment, "I know the judge," pressure to sign blank forms
- **A Court Brief** that explains the courthouse in the document — address, what to expect, what to wear, what to bring — without ever analyzing the judge
- **Questions for legal aid** — a list of the right questions to ask, prepared in advance
- **A Response Preparation Packet** — a printable, multi-section document the user brings to a free legal-aid clinic. It contains a translated summary of what was asked, a plain-language evidence checklist, a pre-filled extension request to buy time, a phone-call script for the legal-aid intake line, and a cover sheet that reads: *"Bring this to your appointment. Your lawyer will write the official response."*

**What Carta Clara doesn't do.** It doesn't give legal advice. It doesn't draft responses to USCIS, EOIR, ICE, or a court. It doesn't tell users which form to file, whether to admit or deny allegations, or whether they qualify for any kind of relief. When asked, it refuses, visibly. The refusal counter in the corner of the screen is part of the user experience, not hidden — every refusal is logged, and the user can tap to see what the app refused to say and which qualified human can answer instead.

"We did not build an AI immigration lawyer," said Picón. "We built a translator that knows when to stop. The refusal is the feature. Everything else is in service of getting grandma to her free legal-aid appointment prepared instead of scared."

**Built on Amazon Bedrock.** Carta Clara uses Amazon Bedrock's multimodal foundation models to understand the document image, Amazon Bedrock Knowledge Bases to ground its explanations in public sources from USCIS, the FTC, EOIR's Practice Manual, and Seattle-area legal-aid organizations, and Amazon Bedrock Guardrails to enforce the refusal of legal-strategy questions and the redaction of personally identifiable information. The entire infrastructure deploys with a single AWS SAM template — six AWS services, four of them Bedrock, no fine-tuning required.

"We treated this like an AWS product, not a demo," said Picón. "One CloudFormation template provisions the whole trust stack. The same architecture works tomorrow for tenant notices, utility shutoffs, school discipline letters, and IRS mail — anywhere a frightening English document lands on a kitchen counter in America."

**Carta Clara is available now as an iPhone app and is free.** The full source code is open for review at github.com/[username]/carta-clara.

---

## Frequently Asked Questions

**Q: How is this different from Google Translate or DeepL?**

A: Translators give you words. Carta Clara gives you a summary, the deadline, the urgent action, a scam check, a court brief, a list of questions for a lawyer, and a printable preparation packet for a free legal-aid appointment. Translation is one of seven features.

**Q: Does Carta Clara give legal advice?**

A: No. Never. Carta Clara explains what a document says and helps the user prepare to talk to a qualified immigration attorney or accredited representative. When asked a legal-strategy question, the app refuses and provides the contact information for a free local legal-aid clinic.

**Q: What happens to the documents I upload?**

A: They're stored in Amazon S3 with a one-hour automatic deletion policy. We do not keep your documents. Our logs record what the system refused to answer — never the contents of your letter.

**Q: Why Spanish only?**

A: We launched with Spanish because that's the language our team can validate every output against a native speaker. Korean, Hindi, Mandarin, and Tagalog are on our roadmap and will launch only as native speakers can validate each one. We refuse to ship a language we cannot verify.

**Q: How can a 70-year-old grandmother use this?**

A: One-handed. The camera button is large and front-and-center. Voice input is the default for asking follow-up questions, with text as a fallback. Audio playback reads the Spanish summary aloud in a human-sounding voice. There is no account to create — no signup, no password, no email field.

**Q: What about Notice to Appear documents — the most serious immigration notice?**

A: Carta Clara handles them carefully. It extracts the hearing date, court name, and address. It generates a "what to expect at this courthouse" brief. It produces a Response Preparation Packet for the legal-aid appointment. It refuses, every time, when asked what to argue or whether to attend — and points the user to a free immigration attorney instead.

**Q: How does this scale beyond immigration?**

A: The same architecture works for every frightening English document a U.S. household receives. Utility shutoff notices. School discipline letters. IRS letters. Lease violations. Insurance denials. Carta Clara's trust stack — visible redaction, source-grounded explanations, refusal of advice, escalation to free human help — is reusable. Immigration is the launch document type because it's where the fear is greatest and the consequences are most serious.

**Q: What does it cost?**

A: Free. Always. Operationally each scan costs a few cents on AWS — Frugality is one of our design constraints, not an afterthought.

**Q: Who validated this product?**

A: Before building, we reached out to Seattle-area immigrant-services organizations including Northwest Immigrant Rights Project, Colectiva Legal del Pueblo, and Refugee Women's Alliance. We did not ask for endorsement. We asked what the tool should never say. Their answers shaped our product — particularly the refusal patterns and the routing-to-human-help workflow.

**Q: Is this an AI lawyer?**

A: No. We will never call it that. It's an AI translator that knows when to refuse and tell you to call a human. That is the entire product.
