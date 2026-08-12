# IntelliJ MCP Skill

This skill lets an agent drive a running IntelliJ IDEA instance through the IntelliJ Companion MCP
server: opening files in the editor, reading which files are open, building the project, and
pulling IDE inspection results. It includes an MCP configuration in [`resources/mcp_config.json`](./resources/mcp_config.json)
for seamless integration with the agent's MCP client.

It is self-contained — no handbook or network references — so it works in any project where
IntelliJ is running with the Companion plugin.
For detailed instructions on how the agent uses this skill, please see [`SKILL.md`](./SKILL.md).

For installation instructions, please see the main [README.md](../../README.md) at the root of the repository.
