---
name: code-review-skill
description: Performs a code review on a GitHub Pull Request given its URL. It asks the user for the GitHub identity to use, then uses the `gh` CLI tool to fetch the PR, perform a thorough code review following the guidelines in `references/CODE_REVIEW.md`, and directly post comments inline on the correct lines of code in GitHub. Trigger this skill whenever a user asks to review a PR, provides a PR link, or wants feedback on a GitHub pull request.
---

# Code Review Skill

This skill performs an automated code review on a GitHub Pull Request using the `gh` CLI, strictly following the guidelines in the handbook file: `references/CODE_REVIEW.md`.

## Workflow

1.  **Identity Verification**: When starting a review, ask the user what GitHub identity/account they want to use for the `gh` CLI operations, if they haven't specified it yet.
2.  **Fetch PR Data**: Use the `gh` CLI tool to fetch the PR details, diffs, and existing comments:
    *   To get the overview: `gh pr view <URL> --json title,body,state,author,headRefName,baseRefName`
    *   To get the diff: `gh pr diff <URL>`
    *   To view existing comments: `gh pr view <URL> --comments`
3.  **Perform and Post Code Review**: Review the code by strictly following the workflow and rules defined in `references/CODE_REVIEW.md`. 
    *   As you perform the review, add your comments directly on the correct line of code in the PR using the `gh` CLI.
    *   To comment on a specific line of code, use the following `gh api` command: `gh api -X POST repos/{owner}/{repo}/pulls/{pull_number}/comments -f body="Your review comment" -f commit_id="{latest_commit_id_of_pr}" -f path="relative/path/to/file" -F line={line_number}`
    *   After adding all inline comments, finalize and submit the formal review (Approve, Request Changes, or Comment) using:
        *   `gh pr review <URL> --approve --body "Looks good to me!"`
        *   `gh pr review <URL> --request-changes --body "Please address the inline comments."`
        *   `gh pr review <URL> --comment --body "General thoughts..."`

## Requirements
- The `gh` CLI must be installed and authenticated.

## Output Format
Post all feedback directly on GitHub. No verbose summaries are needed in the chat besides confirming that the review has been submitted.
