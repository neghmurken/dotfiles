---
name: brainstorm
description: Interview the user one question at a time to stress-test an architecture or implementation decision, then write a handoff document for a fresh agent to pick up. Use when the user invokes /brainstorm.
---

# Brainstorm

## Interview

Interview the user relentlessly about the architecture or implementation decision at hand until the plan is watertight. Walk down each branch of the decision tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer. No open question should be left unresolved unless the user explicitly decides to leave it open.

Ask the questions one at a time, waiting for feedback on each question before continuing. Asking multiple questions at once is bewildering.

If a *fact* can be found by exploring the environment (filesystem, tools, etc.), look it up rather than asking. The *decisions*, though, are the user's — put each one to them and wait for their answer.

Do not implement anything during or after the interview. This skill produces a handoff document, not code.

## Final stress-test pass

Once every branch has a first answer, go back over the whole plan a second time before ending. Challenge every decision against: feasibility, testability, performance, and readability. Look specifically for gaps between decisions, contradictions, and edges nothing yet covers. Raise anything that doesn't hold up as a new question, and resolve it the same way as during the interview.

## Ending the interview

Stop once the decision tree is fully resolved and the stress-test pass turns up nothing new — or the user says to stop.

## Recap before writing

Before writing anything, show a recap to the user and wait for this explicit approval. Address any review feedback.

## Writing the handoff document

Once shared understanding is reached, write `./handoff/{slug}.md` at the repo root (create the `handoff/` directory if it doesn't exist yet), so it gets versioned alongside the project. `{slug}` is a short kebab-case name for the decision, e.g. `handoff/streaming-response-cache.md`.

The document must equip a fresh agent with zero prior context to implement the decision without re-deriving anything — but it is read by a human first, before any agent touches it. Write it for that human: short, light sentences, no padding. Include:

- **Context** — what problem or feature this addresses, and why it matters now. If the user mentioned from an external source (Jira issue for example), mention it here (link, issue number, platform, etc.)
- **Decisions** — each resolved question, the chosen answer, and a one-line rationale (skip trivial ones that need no rationale). Do not include all round-robin passes, just the leaves of the decision tree
- **Implementation details** — the concrete plan: files/modules touched, sequencing, edge cases surfaced during the interview
- **Open questions** — anything the user explicitly chose to leave open (should be rare, since the stress-test pass is meant to close these)

Keep it tight: a fresh agent needs the *what* and *why*, not a transcript of the interview. A human should be able to read the whole thing in under a minute and immediately see whether it's ready to hand off.

This skill is standalone — it does not read or update `CONTEXT.md` or ADRs (that is the `domain-modeling` skill's job). If a decision surfaced during the interview looks ADR-worthy, mention it to the user but don't act on it.
