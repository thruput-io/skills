---
name: pr-review
description: Reviews a GitHub Pull Request against the thruput-io handbook rules and posts the review as inline comments on the correct lines. Distinct from the built-in `/review` skill in that it (a) follows the handbook in `references/CODE_REVIEW.md`, and (b) submits one atomic GitHub review containing all inline comments rather than N individual comments. Trigger when the user provides a PR URL or asks for a handbook-driven PR review.
---

# PR Review Skill

Reviews a GitHub Pull Request using the `gh` CLI, following the guidelines in `references/CODE_REVIEW.md`.

## Bootstrap

`references/CODE_REVIEW.md` is fetched at runtime — it is **not** committed. Run `bash scripts/install.sh` when the file is missing or the user asks to refresh it. (`npx skills update` does not refresh the handbook.)

Recommended: register `bash <absolute-path>/scripts/install.sh` as the host's new-session/startup hook so the handbook auto-refreshes. On first use, offer to wire this up — Claude Code uses a `SessionStart` hook in `.claude/settings.json`; Antigravity and other hosts use their equivalent. Resolve the absolute path from this `SKILL.md`'s location; append to any existing hook list rather than replacing.

## Workflow

### 1. Check auth (do not prompt unless needed)

Run `gh auth status`. Only ask the user which identity to use if auth is missing, or if multiple accounts are listed and no default is set.

### 2. Fetch PR data

- Overview: `gh pr view <URL> --json title,body,state,author,headRefName,baseRefName,headRefOid`
- Diff: `gh pr diff <URL>`
- Existing review comments (to avoid duplicates): `gh api repos/{owner}/{repo}/pulls/{n}/comments`

Extract `headRefOid` from the overview response — this is the `commit_id` required for inline comments. Do **not** guess it; do **not** use `HEAD` of the local checkout.

### 3. Draft comments locally

Read `references/CODE_REVIEW.md` and apply its rules to the diff. Build a JSON array of comments in memory (do not post yet) using `resources/review-comments.template.json` as the shape — one object per comment, substituting each placeholder:

- `{{PATH}}` — repo-relative file path (e.g. `src/foo.ts`).
- `{{LINE}}` — line number in the file **as of the PR head commit**, not the diff hunk offset. Emit as a bare integer (no quotes).
- `{{BODY_WITH_RULE_LINK}}` — the comment body. **Reference the violated rule or principle with an absolute repo URL so the link works from anywhere (e.g., PR comments, external tools).** Each rule has a stable HTML anchor id like `philosophy-achievement-strictness-over-sloppiness`. Example: `[Strictness over sloppiness](https://github.com/thruput-io/handbook/blob/main/PHILOSOPHY.md#philosophy-achievement-strictness-over-sloppiness)`. Follow the link with the concrete problem in this diff.

Additional fields:

- `side` is `RIGHT` for lines added/modified in the PR, `LEFT` for removed lines. The template defaults to `RIGHT`; change it when commenting on a removed line.
- For multi-line comments add `start_line` and `start_side`.

### 4. Submit as a single review

Build a JSON payload:

```json
{
  "commit_id": "<headRefOid>",
  "body": "<overall review body>",
  "event": "APPROVE | REQUEST_CHANGES | COMMENT",
  "comments": [ /* array from step 3 */ ]
}
```

Submit atomically:

```bash
gh api -X POST repos/{owner}/{repo}/pulls/{n}/reviews --input review.json
```

This produces one review, one notification, and all comments are grouped. Do **not** use `POST /pulls/{n}/comments` in a loop — that creates N standalone review comments, N notifications, and is not atomic.

## Requirements

- `gh` CLI installed and authenticated (`gh auth status`).
- `references/CODE_REVIEW.md` present (see Bootstrap).

## Files

- `scripts/install.sh` — fetches the handbook from `github.com/thruput-io/handbook` into `references/`.
- `resources/review-comments.template.json` — shape for the comments array built in step 3; placeholders: `{{PATH}}`, `{{LINE}}`, `{{BODY_WITH_RULE_LINK}}`.
- `tests/verify_install.sh` — smoke test for `install.sh`.
