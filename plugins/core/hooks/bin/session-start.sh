#!/usr/bin/env bash
# SessionStart: record that a session began. Passive; never blocks.
set -euo pipefail

data_dir="${GROK_PLUGIN_DATA:-${TMPDIR:-/tmp}/grok-plugin-core}"
mkdir -p "$data_dir"

printf '%s event=%s session=%s workspace=%s\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  "${GROK_HOOK_EVENT:-session_start}" \
  "${GROK_SESSION_ID:-unknown}" \
  "${GROK_WORKSPACE_ROOT:-unknown}" \
  >>"$data_dir/sessions.log"

exit 0
