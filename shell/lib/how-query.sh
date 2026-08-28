# Ask grok for a single shell command. Sourced by zsh and bash how functions.

_ps_how_query() {
  command grok -p "$*" \
    --max-turns 1 \
    --tools "" \
    --no-subagents \
    --disable-web-search \
    --rules \
    "You are a command-line expert. Respond with ONLY the command itself - no explanation, no markdown, no code blocks." \
    2>/dev/null
}

_ps_how_strip() {
  printf '%s\n' "$1" |
    sed '/^mise .* tools:/d' |
    sed 's/^```[a-zA-Z0-9]*$//' |
    sed 's/^```$//' | sed '/^$/d' | tr -d '`'
}
