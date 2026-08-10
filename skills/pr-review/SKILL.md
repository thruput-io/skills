---
name: pr-review
description: Reviews a GitHub Pull Request against the thruput-io handbook rules and posts the review as inline comments on the correct lines. Distinct from the built-in `/review` skill in that it (a) follows the handbook at `github.com/thruput-io/handbook` (specifically `CODE_REVIEW.md`), and (b) submits one atomic GitHub review containing all inline comments rather than N individual comments. Trigger when the user provides a PR URL or asks for a handbook-driven PR review.
---

# PR Review Skill

Access the handbook repository directly at `github.com/thruput-io/handbook` (specifically [`CODE_REVIEW.md`](https://github.com/thruput-io/handbook/blob/main/CODE_REVIEW.md)) and follow it. It is the source of truth for both what to review and how to execute the review via the `gh` CLI.

The `resources/review-comments.template.json` file shows the shape of a single comment object referenced by `CODE_REVIEW.md` step 4.

## Requirements

- `gh` CLI installed and authenticated (`gh auth status`).
- Access to `github.com/thruput-io/handbook` repository.

## Files

- `resources/review-comments.template.json` — shape of a single comment object.
- `examples/review-comments.sample.json` — sample review comments.
