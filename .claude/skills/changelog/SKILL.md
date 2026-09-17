---
name: changelog
description: Generate a French release changelog from git commits between two tags, grouped by bounded context with emoji section headers. Use when user invokes /changelog [tag] or asks to write a release changelog.
triggers:
  - /changelog
---

# Changelog Generator

## Trigger

`/changelog [tag]` — generate changelog for `[tag]`. If tag omitted, use latest git tag.

## Process

### 1. Resolve tags

```bash
# Latest tag (if no arg given)
CURRENT=$(git describe --tags --abbrev=0)

# Previous tag
PREVIOUS=$(git describe --tags --abbrev=0 "${CURRENT}^")
```

### 2. Get commits

Tool output is truncated silently past a line/byte limit — never trust a raw terminal read of `git log` for the full list. Always redirect to a file and verify the count before parsing:

```bash
git log --pretty=format:"%s" "${PREVIOUS}..${CURRENT}" > /tmp/changelog-commits.txt
wc -l /tmp/changelog-commits.txt
```

Read the file back (or cat it) to get the actual full list — do not rely on the count alone. If the count looks suspiciously round (e.g. exactly 50) or small for the tag range, re-verify with `git rev-list --count "${PREVIOUS}..${CURRENT}"` and compare.

Filter out lines matching:
- `^Bump ` (dependabot bumps)
- `^Merge ` (merge commits)
- `^chore\(deps\)` and `^chore\(deps-dev\)` (dependency chores, both runtime and dev)
- a version-only subject matching the tag name itself (e.g. a lone `v3.37` release/version-bump commit)

### 3. Enrich with PR data

For each commit that references a PR number (`#\d+` or `/pull/\d+`), use `gh pr view <number> --json title,body,labels,url` to get richer context if the commit message is unclear.

Also check: `gh release view ${PREVIOUS}` to understand what was already shipped (avoid duplicates).

Also exclude, treating them like dependency chores (no separate changelog entry):
- Internal AI-tooling docs (e.g. PRs adding/updating `AGENTS.md`, Claude/agent instructions) — not product-facing.
- Pure git-housekeeping fixes (e.g. "fix broken rebase/merge") whose diff only repairs conflicts from another PR already listed — no standalone product change.

### 4. Group by bounded context

Infer context from commit/PR content. Known contexts in this project:

| Context | Emoji | Keywords |
|---------|-------|----------|
| Creative Factory / CF | `:gear:` | creative factory, CF, task chain, capabilities, actions |
| PLV | `:art:` | PLV, gabarit, omnipublish, nomenclature, fab |
| Bug fixes | `:bug:` | correction, régression, fix, bug |
| Refacto | `:sparkles:` | refacto, rector, legacy, suppression, dead code, cleanup |
| Metrics / Observabilité | `:bar_chart:` | bugsnag, metrics, monitoring, observabilité, logs |
| Infrastructure / CI | `:wrench:` | docker, CI, deploy, migration, deps upgrade |
| Panel | `:tv:` | panel, temps réel, realtime |
| Frontend | `:computer:` | frontend, UI, interface, écran |

A commit can only appear in one section. Prefer the most specific context.
Bump/infra dependency bumps → skip entirely unless they are major version upgrades worth noting.

### 5. Output the changelog

**Format** (match v3.32 style):

```markdown
## What's Changed

### :gear: Creative factory

* Description succincte en français by @author in https://github.com/cacom-production/anaka/pull/XXXX

### :bug: Bug fixes

* Correction de ... by @author in #XXXX

**Full Changelog**: https://github.com/cacom-production/anaka/compare/${PREVIOUS}...${CURRENT}
```

**Rules:**
- French only (except proper nouns, tech terms)
- One bullet per logical change (group related PRs on same line with `&` if they implement one feature)
- Keep PR number/URL — prefer full URL format `https://github.com/cacom-production/anaka/pull/XXXX`
- Author format: `@username` (from git log or gh pr view)
- Omit sections with no entries
- Descriptions: concise, action verb first (e.g. "Ajout de...", "Correction de...", "Suppression de...", "Migration de...")
- Do NOT add entries for Bump/Merge/chore(deps) commits
