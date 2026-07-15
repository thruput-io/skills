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
3.  **Perform and Submit Code Review**:
    *   You must follow the workflow by the handbook: `https://github.com/thruput-io/handbook/blob/main/CODE_REVIEW.md`.


    **CRITICAL**: Do NOT present findings to the user for approval first. As you perform the review, add your comments directly on the correct line of code in the PR using the `gh` CLI.
    *   To comment on a specific line of code, use the following `gh api` command:
        `gh api -X POST repos/{owner}/{repo}/pulls/{pull_number}/comments -f body="Your review comment" -f commit_id="{latest_commit_id_of_pr}" -f path="relative/path/to/file" -F line={line_number}`
    *   After adding all inline comments, submit the formal review (Approve, Request Changes, or Comment):
        *   `gh pr review <URL> --approve --body "Looks good to me!"`
        *   `gh pr review <URL> --request-changes --body "Please address the inline comments."`
        *   `gh pr review <URL> --comment --body "General thoughts..."`

## Requirements
— The `gh` CLI must be installed and authenticated.

## Output Format
Only the actual review in Github.
