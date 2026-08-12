---
name: intellij-mcp
description: Drive a running IntelliJ IDEA instance over the IntelliJ Companion MCP server (`intellij-stream`, streamable-http on 127.0.0.1:64342) to open files, read editor state, build, and lint. Trigger when a task needs the IDE itself — opening a file for the human to see, compiling through IntelliJ, or reading IDE inspection results — rather than plain file edits.
---

# IntelliJ Companion MCP

The IntelliJ Companion plugin exposes a running IntelliJ IDEA instance as an MCP server over streamable-http at `http://127.0.0.1:64342/stream`. Use this skill when the IDE context is required: displaying files directly in the editor, building via the IDE build system, or retrieving live IntelliJ inspection warnings and errors.

## 1. Setup & Configuration

This skill includes an MCP configuration in [`resources/mcp_config.json`](./resources/mcp_config.json).

To activate the server for your agent, copy or merge the configuration into your workspace `.agents/mcp_config.json` or global `~/.gemini/config/mcp_config.json`:

```json
{
  "mcpServers": {
    "intellij-stream": {
      "type": "streamable-http",
      "url": "http://127.0.0.1:64342/stream",
      "headers": {
        "IJ_MCP_SERVER_PROJECT_PATH": "${IJ_MCP_SERVER_PROJECT_PATH}",
        "X-IDE-User": "${USER}",
        "X-IDE-Home": "${HOME}"
      }
    }
  }
}
```

When configured, the client handles protocol connection, session header initialization, and streamable-http transport automatically behind the scenes.

## 2. Targeting a Project

IntelliJ requires every tool call to identify the target open project. Specify the target project using either:
- **Tool Argument (Recommended)**: Pass `projectPath: "/absolute/path/to/project-root"` in the arguments of any tool call.
- **Environment Variable**: Set `IJ_MCP_SERVER_PROJECT_PATH=$(pwd)` before starting the agent session.

*Note: `projectPath` must be the project root directory currently open in IntelliJ, not individual file paths.*

## 3. Calling Tools

When the server is connected, invoke its tools directly:

| Tool | Key Arguments | Purpose |
| --- | --- | --- |
| `open_file_in_editor` | `filePath`, `projectPath` | Focus and display a file in the human's IDE editor |
| `get_all_open_file_paths` | `projectPath` | Retrieve currently active and open editor tabs |
| `build_project` | `rebuild`, `filesToRebuild`, `projectPath` | Trigger IDE compilation and collect compiler errors |
| `get_file_problems` | `filePath`, `errorsOnly`, `projectPath` | Run IDE code inspections for a specific file |
| `lint_files` | `files`, `min_severity`, `projectPath` | Batch lint multiple files using IntelliJ inspections |

`filePath` may be given relative to the project root; results report paths that way too.

## 4. Diagnostics & Troubleshooting

| Error / Symptom | Cause | Resolution |
| --- | --- | --- |
| `Unable to determine the target project` | Missing project scoping | Supply `projectPath` in tool call arguments or set `IJ_MCP_SERVER_PROJECT_PATH` |
| Connection refused on `127.0.0.1:64342` | IntelliJ closed or plugin inactive | Ask human to ensure IntelliJ IDEA is running with the Companion plugin active |
| `Bad Request: Server not initialized` (400) | Missing session state | Re-initialize the MCP connection in client |
| `Streamable HTTP session not found` | Session expired | Re-initialize connection and retry tool call |

---

## Appendix: Manual HTTP Fallback (For Raw Testing)

If native MCP tool integration is unavailable in your environment, perform the JSON-RPC streamable-http handshake manually via `curl`:

1. **Initialize Session**:
   ```bash
   curl -sS -D headers.txt -X POST http://127.0.0.1:64342/stream \
     -H 'Content-Type: application/json' \
     -H 'Accept: application/json, text/event-stream' \
     -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"agent","version":"1"}}}'
   SID=$(grep -i '^mcp-session-id' headers.txt | tr -d '\r' | awk '{print $2}')
   ```

2. **Send Initialized Notification**:
   ```bash
   curl -sS -X POST http://127.0.0.1:64342/stream \
     -H 'Content-Type: application/json' \
     -H "Mcp-Session-Id: $SID" \
     -d '{"jsonrpc":"2.0","method":"notifications/initialized"}'
   ```

3. **Execute Tool Call**:
   ```bash
   curl -sS -X POST http://127.0.0.1:64342/stream \
     -H 'Content-Type: application/json' \
     -H "Mcp-Session-Id: $SID" \
     -H "IJ_MCP_SERVER_PROJECT_PATH: $PROJECT_ROOT" \
     -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"open_file_in_editor","arguments":{"filePath":"README.md"}}}'
   ```
