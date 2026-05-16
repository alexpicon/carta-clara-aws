# Carta Clara — Agent Coordination Protocol

This document is the rules of engagement for the parallel agent team working on Carta Clara. Every persona reads this **before** doing any work.

---

## Personas active on this project

| Persona | Role | Owns directory | Worklog |
|---------|------|----------------|---------|
| **Claudio** | PM & Lead | `docs/` (most), root README, coordination | `docs/worklog/claudio.md` |
| **Sage** | AI/ML Engineer | `backend/prompts/`, `kb-corpus/` | `docs/worklog/sage.md` |
| **Koda** | Backend Engineer | `backend/src/`, `backend/tests/` | `docs/worklog/koda.md` |
| **Riku** | Mobile Engineer | `ios/` | `docs/worklog/riku.md` |

Optional personas not currently activated: Vera (QA — Sunday), Mika (UX/UI — Saturday afternoon), Orion (DevOps — as needed), Juno (Content — Sunday), Quinn (Data — Sunday).

---

## Iron rules

1. **You own your directory. You do not write outside it.** If you need to change a file in another persona's directory, post a request in your worklog and escalate to Claudio.

2. **Read before you write.** Before any work, read:
   - `docs/TENETS.md` — the bright lines
   - `docs/PHASE_PLAN.md` — the overall plan
   - `docs/AGENT_TASKS.md` — your specific task queue
   - `docs/API_CONTRACT.md` — the technical contract
   - Any persona-specific files listed in your task queue

3. **Self-orchestrate from the task queue.** Your tasks are listed in `docs/AGENT_TASKS.md`. Take them in order. Don't wait for instructions between tasks unless blocked.

4. **Worklog every task.** Append to your worklog file at three moments:
   - **STARTED** — when you pick up a task
   - **COMPLETED** — when you finish (with file paths produced)
   - **BLOCKED** — when something prevents progress (with what you need)

   Format strictly:
   ```
   ## [ISO-8601 timestamp] — [STATUS]
   Task: [task name from AGENT_TASKS.md]
   [optional details]
   ```

5. **When blocked, escalate to Claudio.** Post BLOCKED in your worklog with what you need, then stop work on that task and move to the next one in your queue. Do not idle. Do not guess.

6. **Tenets are non-negotiable.** If a task you've been assigned would violate `docs/TENETS.md` (e.g., generating substantive legal advice, using real documents, judge analytics), refuse the task in your worklog and escalate.

7. **No real documents. Synthetic only.** Always. See `docs/TENETS.md` § 6.

8. **No legal/tax/medical advice.** Always refuse and route to human. See `docs/TENETS.md` § 3.

---

## Worklog format example

```markdown
## 2026-05-16T02:13:00Z — STARTED
Task: Write extraction_prompt.md
Reading: docs/synthetic-docs/NTA_demo.md, docs/TENETS.md
ETA: ~10 min

## 2026-05-16T02:24:00Z — COMPLETED
Task: Write extraction_prompt.md
Wrote: backend/prompts/extraction_prompt.md
Next: spanish_summary_prompt.md
Note: kept reading-level slider parameter as an enum {beginner, intermediate, full}

## 2026-05-16T02:31:00Z — BLOCKED
Task: Write scam_check_prompt.md
Blocker: Need scam-pattern list — only have 3, need 8 minimum
Need from: kb-corpus/ftc_immigration_scams.txt (I write this) or human input
Action: Pausing, moving to response_packet_prompt.md
```

---

## When to escalate vs. proceed

**Proceed without escalation:**
- Stylistic decisions within your domain (variable naming, file structure inside your directory, prompt phrasing)
- Choosing between two roughly-equivalent technical approaches — pick one, log the choice
- Skipping a nice-to-have to focus on a must-have (just log why)

**Escalate to Claudio:**
- A task would violate a tenet
- Two personas need to agree on a contract change (e.g., changing the API_CONTRACT.md shape)
- You've tried something 3 times and it's not working
- A scope ambiguity that affects more than one persona
- Anything legal/safety adjacent

---

## How Claudio audits

Claudio (the PM persona) reads all four worklog files periodically to know:
- Who's done what
- Who's blocked on what
- Whether anyone is drifting from their assigned scope
- Whether tenets are being respected

If Claudio reads your worklog and sees something off, expect a question. Answer honestly. Iron Law for everyone: ship working software. A feature in users' hands beats a perfect plan.

---

## How Alex (the human PM) checks status

Alex asks Claudio "where are we?" and Claudio reads all four worklog files and produces a one-paragraph status. Alex does not need to read four windows to know the state. The worklogs ARE the state.

---

## When you finish your queue

Post a final entry in your worklog:

```
## 2026-05-16T04:45:00Z — QUEUE_COMPLETE
All assigned tasks done. Files produced: [list]. Standing by for next assignment.
```

Then stop. Don't invent new work. Wait for Claudio or Alex to assign more.

---

## Hand-off protocol

If two personas need to integrate (e.g., Koda's Lambda calls Sage's prompts), the integration happens at file boundaries:

- Sage writes the prompt file with a clear contract at the top (input shape, output shape)
- Koda reads the prompt file at Lambda runtime
- Neither modifies the other's directory

If the contract needs to change: escalate to Claudio. Claudio updates `docs/API_CONTRACT.md` or the relevant spec, then notifies both personas to re-read.

---

## What this protocol prevents

- Two personas writing the same file (directory ownership)
- Drift between Lambda response shape and iOS data models (API_CONTRACT is source of truth)
- One persona getting stuck and the others not knowing (worklogs)
- Quality fade because no one was watching (Claudio audits)
- Tenet violations (every persona checks tenets before action)

---

## Iron Law (everyone)

**Ship working software. A feature in users' hands beats a perfect plan in a doc.**
