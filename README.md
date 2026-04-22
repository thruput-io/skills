# AI Agent Skills Repository

This repository contains a collection of AI agent skills that are versioned and reviewed like normal project assets. Externalizing skills here (instead of in an agent's private directory like `.gemini/` or `.agent/`) makes them easier to share, publish, and manage.

## Available Skills

-   [`skills/e2e-testing`](./skills/e2e-testing): A skill for generating reliable, end-to-end integration tests for dotnet backend projects.

## Installation

To install a skill for your local AI agent, you can use the `npx skills` command-line tool.

### From this Git Repository

This is the recommended way to install skills. You can install any skill directly from this repository by referencing its path.

For example, to install the `e2e-testing` skill:

```bash
npx skills install git+https://github.com/thruput-io/skills.git/skills/e2e-testing
```

### From a Local Directory

If you are developing a skill locally, you can install it from its directory path. From the root of this repository, run:

```bash
npx skills install skills/e2e-testing
```

This will link the skill from its source directory into your agent's runtime environment.
