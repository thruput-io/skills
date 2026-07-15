---
name: code-review-skill
description: Performs a code review on a GitHub Pull Request given its URL. It asks the user for the GitHub identity to use and uses the `gh` CLI tool to interact with GitHub to fetch the PR details, diffs, and post comments or reviews. Trigger this skill whenever a user asks to review a PR, provides a PR link, or wants feedback on a GitHub pull request.
---

# Code Review Skill

This skill performs a code review on a GitHub Pull Request using the `gh` CLI.

## Workflow

1.  **Identity Verification**: When starting a review, ask the user what GitHub identity/account they want to use for the `gh` CLI operations, if they haven't specified it yet.
2.  **Fetch PR Data**: Use the `gh` CLI tool to fetch the PR details, the diff, and current comments.
    *   To get the overview and description: `gh pr view <URL> --json title,body,state,author,headRefName,baseRefName`
    *   To get the code changes (diff): `gh pr diff <URL>`
    *   To view existing review comments to avoid duplicates: `gh pr view <URL> --comments`
3.  **Perform and Submit Code Review**: When executing the code review, you must follow the guidelines and instructions outlined in the handbook: `https://github.com/thruput-io/handbook/blob/main/CODE_REVIEW.md`. Additionally, analyze the diffs for:
    *   Check for Bugs or logic errors (see `references/bugs.md`)
    *   Check for Security vulnerabilities (see `references/security.md`)
    *   Check for Performance issues (see `references/performance.md`)
    *   Check for Style and readability improvements (see `references/style.md`)

    **CRITICAL**: Do NOT present findings to the user for approval first. As you perform the review, add your comments directly on the correct line of code in the PR using the `gh` CLI.
    *   To comment on specific lines, you may need to use `gh api` or the appropriate `gh pr review` features.
    *   After adding inline comments, submit the formal review (Approve, Request Changes, or Comment):
        *   `gh pr review <URL> --approve --body "Looks good to me!"`
        *   `gh pr review <URL> --request-changes --body "Please address the inline comments."`
        *   `gh pr review <URL> --comment --body "General thoughts..."`

## Requirements
— The `gh` CLI must be installed and authenticated.

## Output Format
Only the actual review in Github.
