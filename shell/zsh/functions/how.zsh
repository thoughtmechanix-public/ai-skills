# how — ask grok for a shell command, copy it, and put it on the editing buffer.

_how() {
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

  if _ps_copy "$result"; then
    echo "Command ready (also copied to clipboard):"
  else
    echo "Command ready:"
  fi
  print -z "$result"
}

alias how='noglob _how'
