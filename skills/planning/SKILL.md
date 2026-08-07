---
name: planning
description: Co-author an implementable plan for one problem with the human, through evidence-driven interrogation, following the thruput-io handbook PLANNING.md. Trigger when the user asks to plan, design, scope, or investigate an approach before building. Produces a committed plan under docs/plans/ that an implementing agent can follow and verify, and ends by asking permission to push and open a PR. Never writes production code.
---

# Planning Skill

Read <https://raw.githubusercontent.com/thruput-io/handbook/main/PLANNING.md> and follow it. It is the
source of truth for how planning is conducted, what the plan must contain, and how the session
ends.

Read <https://raw.githubusercontent.com/thruput-io/handbook/main/PLAN_TEMPLATE.md> when you reach
[`PLANNING.md` § Plan format](https://raw.githubusercontent.com/thruput-io/handbook/main/PLANNING.md#plan-format). Copy it into the target project as
`docs/plans/{plan-name}/{NNN}-{plan-name}.md` and fill it in.

Both are referenced, never vendored — the handbook is the single source of truth, so always
read the current version rather than a cached copy.

## Before you start

[`PLANNING.md` § Preflight](https://raw.githubusercontent.com/thruput-io/handbook/main/PLANNING.md#preflight) is a hard gate. Run it before asking the human anything: confirm you
can write files, run the project's tests, run `git commit`, and reach the network; confirm the
working tree is clean; read [`RULES.md`](https://raw.githubusercontent.com/thruput-io/handbook/main/RULES.md), [`PHILOSOPHY.md`](https://raw.githubusercontent.com/thruput-io/handbook/main/PHILOSOPHY.md), [`WORKFLOW.md`](https://raw.githubusercontent.com/thruput-io/handbook/main/WORKFLOW.md), and the project's ADRs.
Stop and tell the human if any check fails.

## Boundaries

- This skill plans. It **MUST NOT** write, modify, or refactor production code. The only code it
  writes is exploratory tests, under `{test-context}/exploratory/{plan-name}/` in the project's
  own test tree.
- It **MUST NOT** push or open a pull request without asking the human first.
- It **MUST NOT** begin implementation. Implementation is a separate activity on its own branch.

## Related

- `pr-review` — reviews the pull request this skill's plan eventually produces.
