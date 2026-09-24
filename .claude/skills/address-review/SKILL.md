---
name: address-review
description: Triage and resolve GitHub pull request review feedback one comment at a time — fetch review-body, conversation, and inline comments, filter out low-value ones (thanks/jokes/nitpick-acks), then for each remaining comment summarize it, fact-check it against the actual code, and ask the user whether to address or skip it. Approved comments get a proposed plan, user-approved implementation, and a review pass before being marked resolved with a 👍 reaction. Use when the user asks to address/resolve PR review comments, process reviewer feedback, or work through comments left on a pull request.
---

# Address Review

Resolve reviewer comments on a pull request interactively, one at a time, never editing without explicit user approval.

## Setup

1. Determine PR number: try `gh pr view --json number -q .number`. If it fails (no PR for current branch, detached HEAD, etc.), ask the user for the PR number.
2. Determine owner/repo: `gh repo view --json owner,name -q '.owner.login + "/" + .name'`.
3. Determine the current GitHub login: `gh api user -q .login`.

## Fetch comments

Run `scripts/fetch-comments.sh <owner> <repo> <pr_number> <login>`. It returns:

```json
{"review_bodies": [...], "conversation": [...], "inline": [...]}
```

Each conversation/inline entry has `addressed: true` if the current user already 👍'd it, or (inline only) if the comment's review thread is already marked **Resolved** natively on GitHub (re-run safe — skip these silently, don't show them again). Review-body entries can never carry a reaction or belong to a thread, so they always report `addressed: false`; re-running the skill will show them again — mention this to the user rather than pretending otherwise.

## Filter

Omit any entry with `addressed: true` (already 👍'd, or already resolved on GitHub) — never list these, don't count them among filtered-out items either.

Process the three groups **in order: review_bodies, then conversation, then inline**. Within each group, split out low-value comments — pure thanks, jokes, "LGTM", emoji-only reactions restated as text, simple acknowledgments with nothing actionable. Print the filtered-out ones as a one-line list (`author: first few words...`) so the user can pull one back in if it was misjudged. Do not ask approval per filtered item — just list them, then proceed with the rest.

## Resolve loop

For each remaining comment, in order:

1. **Summarize** the comment in one or two sentences.
2. **Fact-check** it: read the referenced file/lines (for inline comments, use `path`/`line`/`diff_hunk`) and verify the claim holds before taking it at face value — don't assume the reviewer is right.
3. **Ask the user** (interactive question): address this comment, or skip it? Show the summary, fact-check result, and a link (`url`).
4. **If skipped**: move to the next comment. Leave it untouched on GitHub — no reaction, no reply.
5. **If addressed**:
   - Propose a concrete implementation plan. Wait for explicit user approval before writing any code.
   - Implement the approved plan.
   - Let the user review the diff and commit it themselves. Do not commit on their behalf unless they explicitly ask.
   - Once the user confirms the change is committed, mark it resolved:
     - `conversation`/`inline` types: `scripts/mark-addressed.sh <owner> <repo> <type> <id>`.
     - `review_body` type: cannot be marked (no reaction endpoint on reviews) — just confirm verbally that it's handled for this session.

## Notes

- Never batch-approve or batch-implement multiple comments at once — one comment fully resolved (or skipped) before moving to the next.
- If a comment references code that no longer exists (renamed/deleted since the review), say so explicitly instead of guessing at intent.
