#!/bin/bash
set -e

INPUT=$(cat)

# Extract CommandLine from Antigravity PreToolUse payload, or fall back to tool_input.command for Claude
COMMAND=$(echo "$INPUT" | jq -r '.toolCall.args.CommandLine // .tool_input.command // empty' 2>/dev/null || true)

if [ -z "$COMMAND" ]; then
  echo '{"decision":"allow"}'
  exit 0
fi

DANGEROUS_PATTERNS=(
  "git push"
  "git reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  "git checkout \."
  "git restore \."
  "push --force"
  "reset --hard"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    REASON="BLOCKED: '$COMMAND' matches dangerous pattern '$pattern'. Destructive git operations are restricted by git-guardrails."
    if echo "$INPUT" | jq -e '.tool_input' >/dev/null 2>&1; then
      echo "$REASON" >&2
      exit 2
    else
      jq -n --arg reason "$REASON" '{"decision": "deny", "reason": $reason}'
      exit 0
    fi
  fi
done

echo '{"decision":"allow"}'
exit 0
