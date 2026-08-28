# how — ask grok for a single shell command, copy it, and add it to bash history.
# alias how='set -f; _how' so globs in the query are not expanded.

_how() {
  set +f
  if [[ -z "$*" ]]; then
    echo "Usage: how <what command do you need?>"
    return 1
  fi
  if ! command -v grok >/dev/null 2>&1; then
    echo "how: grok is not on PATH" >&2
    return 127
  fi

  local result
  result="$(_ps_how_query "$@")"
  result="$(_ps_how_strip "$result")"
  if [[ -z "$result" ]]; then
    echo "how: grok returned no command" >&2
    return 1
  fi

  _ps_copy "$result" || true
  history -s -- "$result"
  echo "Command ready (also copied to clipboard):"
  printf '%s\n' "$result"
}

alias how='set -f; _how'
