---
name: pr-review
description: Reviews a GitHub Pull Request against the thruput-io handbook rules and posts the review as inline comments on the correct lines. Distinct from the built-in `/review` skill in that it (a) follows the handbook in `references/CODE_REVIEW.md`, and (b) submits one atomic GitHub review containing all inline comments rather than N individual comments. Trigger when the user provides a PR URL or asks for a handbook-driven PR review.
---

# PR Review Skill

Reviews a GitHub Pull Request using the `gh` CLI, following the guidelines in `references/CODE_REVIEW.md`.

## Bootstrap (run once, or when handbook is stale)

`references/CODE_REVIEW.md` is fetched at runtime — it is **not** committed to the skill. Before starting a review:

1. If `references/CODE_REVIEW.md` does not exist, run `bash scripts/install.sh`.
2. If the user asks to refresh the handbook, re-run `bash scripts/install.sh`.

`npx skills update` refreshes SKILL.md and `scripts/install.sh`; it does **not** refresh the handbook cache — that is what `install.sh` is for.

## Workflow

### 1. Check auth (do not prompt unless needed)

Run `gh auth status`. Only ask the user which identity to use if auth is missing, or if multiple accounts are listed and no default is set.

### 2. Fetch PR data

- Overview: `gh pr view <URL> --json title,body,state,author,headRefName,baseRefName,headRefOid`
- Diff: `gh pr diff <URL>`
- Existing review comments (to avoid duplicates): `gh api repos/{owner}/{repo}/pulls/{n}/comments`

Extract `headRefOid` from the overview response — this is the `commit_id` required for inline comments. Do **not** guess it; do **not** use `HEAD` of the local checkout.

### 3. Draft comments locally

Read `references/CODE_REVIEW.md` and apply its rules to the diff. Build a JSON array of comments in memory (do not post yet):

```json
[
  {
    "path": "src/foo.ts",
    "line": 42,
    "side": "RIGHT",
    "body": "This branch will NPE when `user` is null — the check on line 39 only covers the happy path."
  }
]
```

- `line` is the line number in the file **as of the PR head commit**, not the diff hunk offset.
- `side` is `RIGHT` for lines added/modified in the PR, `LEFT` for removed lines.
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

### 5. Confirm

Print the review URL from the API response. Do not restate the review content in chat — the user can read it on GitHub.

## Requirements

- `gh` CLI installed and authenticated (`gh auth status`).
- `references/CODE_REVIEW.md` present (see Bootstrap).

## Files

- `scripts/install.sh` — fetches the handbook from `github.com/thruput-io/handbook` into `references/`.
- `tests/verify_install.sh` — smoke test for `install.sh`.
