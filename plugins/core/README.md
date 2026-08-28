# core

Session-wide Grok hooks. This plugin has no skills on purpose: safety and logging should not depend on which domain plugin is enabled.

| Event | Handler | Behavior |
|---|---|---|
| `SessionStart` | `hooks/bin/session-start.sh` | Append one line to `$GROK_PLUGIN_DATA/sessions.log` |
| `PreToolUse` (`Bash`) | `hooks/bin/deny-destructive.sh` | Deny `rm -rf /`, `mkfs`, `dd` to block devices, fork bombs |
| `PostToolUse` | `hooks/bin/log-tool-use.sh` | Append a truncated JSONL line to `$GROK_PLUGIN_DATA/tool-use.jsonl` |

Disable an individual hook in the Grok Hooks tab (`/hooks`) if it is too noisy.
