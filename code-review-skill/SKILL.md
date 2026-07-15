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
3.  **Perform Code Review**: When executing the code review, you must follow the guidelines and instructions outlined in `references/CODE_REVIEW.md`. Additionally, analyze the diffs for:
    *   Check for Bugs or logic errors (see `references/bugs.md`)
    *   Check for Security vulnerabilities (see `references/security.md`)
    *   Check for Performance issues (see `references/performance.md`)
    *   Check for Style and readability improvements (see `references/style.md`)
4.  **Present and Submit the Review**:
    *   First, present the findings to the user clearly. 
    *   If the user approves, you can submit the review using the `gh` CLI.
    *   To add a general comment to the PR: `gh pr comment <URL> --body "Your comment here"`
    *   To submit a formal review (Approve, Request Changes, or Comment):
        *   `gh pr review <URL> --approve --body "Looks good to me!"`
        *   `gh pr review <URL> --request-changes --body "Please address the following issues..."`
        *   `gh pr review <URL> --comment --body "Just some thoughts..."`

## Requirements
- The `gh` CLI must be installed and authenticated.

## Output Format
When presenting the review to the user:
*   Start with a brief executive summary of the changes.
*   List issues by severity (e.g., Critical, Suggestion, Nitpick).
*   For each issue, specify the file name and provide a snippet of the code in question along with your suggested fix.
