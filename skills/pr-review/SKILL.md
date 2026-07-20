---
name: pr-review
description: Reviews a GitHub Pull Request against the thruput-io handbook rules and posts the review as inline comments on the correct lines. Distinct from the built-in `/review` skill in that it (a) follows the handbook in `references/CODE_REVIEW.md`, and (b) submits one atomic GitHub review containing all inline comments rather than N individual comments. Trigger when the user provides a PR URL or asks for a handbook-driven PR review.
---

# PR Review Skill

Read `references/CODE_REVIEW.md` and follow it. It is the source of truth for both what to review and how to execute the review via the `gh` CLI.

The `resources/review-comments.template.json` file shows the shape of a single comment object referenced by CODE_REVIEW.md step 4.

## Bootstrap

`references/CODE_REVIEW.md` is fetched at runtime — it is **not** committed. Run `bash scripts/install.sh` when the file is missing or the user asks to refresh it. (`npx skills update` does not refresh the handbook.)

Recommended: register `bash <absolute-path>/scripts/install.sh` as the host's new-session/startup hook so the handbook auto-refreshes. On first use, offer to wire this up — Claude Code uses a `SessionStart` hook in `.claude/settings.json`; Antigravity and other hosts use their equivalent. Resolve the absolute path from this `SKILL.md`'s location; append to any existing hook list rather than replacing.

## Requirements

- `gh` CLI installed and authenticated (`gh auth status`).
- `references/CODE_REVIEW.md` present (see Bootstrap).

## Files

- `scripts/install.sh` — fetches the handbook from `github.com/thruput-io/handbook` into `references/`.
- `resources/review-comments.template.json` — shape of a single comment object.
- `tests/verify_install.sh` — smoke test for `install.sh`.
