# e2e-testing skill (externalized)

This folder contains a productized, GitHub-friendly copy of the `e2e-testing` Junie skill.

## Why this exists

- Keeps the skill out of `.junie/` so it can be versioned and reviewed like normal project assets.
- Makes it easier to copy/package/publish the skill to a dedicated repository later.

## Folder contract

- `SKILL.md` — skill metadata and concise operating guidance.
- `examples/E2ETestStyleTemplate.cs` — full end-to-end test template.
- `examples/README.md` — notes on adapting examples safely.

## Local usage

Use this folder as your source of truth when you want to install or package the skill:

- Skill path: `skills/e2e-testing`

If you keep a local `.junie/skills/e2e-testing` copy for runtime, treat it as a build/install target generated from this source.

## GitHub setup suggestion

You can now:

1. Commit this folder in the current repository, or
2. Copy `skills/e2e-testing` into a dedicated repo (for example `maintenance-monitor-skills/e2e-testing`).

For dedicated repos, keep this folder structure intact so tooling can find `SKILL.md` at the skill root.