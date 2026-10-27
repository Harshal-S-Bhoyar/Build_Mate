---
name: git-guardrails
description: Set up lifecycle hooks to block dangerous git commands (push, reset --hard, clean, branch -D, etc.) before they execute in Antigravity or Claude Code. Use when user wants to prevent destructive git operations, add git safety hooks, or block git push/reset.
---

# Setup Git Guardrails

Sets up a PreToolUse hook that intercepts and blocks dangerous git commands before they execute.

## What Gets Blocked

- `git push` (all variants including `--force`)
- `git reset --hard`
- `git clean -f` / `git clean -fd`
- `git branch -D`
- `git checkout .` / `git restore .`

When blocked, the agent receives a deny decision explaining that the command is restricted.

## Setup in Antigravity

Antigravity uses `hooks.json` (placed in `~/.gemini/config/hooks.json` globally, or `.agents/hooks.json` for project scope).

### 1. Hook Script Location

Use the bundled script:
`~/.gemini/config/skills/git-guardrails/scripts/block-dangerous-git-antigravity.sh`

Ensure it is executable (`chmod +x`).

### 2. Configuration (`hooks.json`)

Add to `~/.gemini/config/hooks.json` (global) or `.agents/hooks.json` (project):

```json
{
  "git-guardrails": {
    "PreToolUse": [
      {
        "matcher": "run_command",
        "hooks": [
          {
            "type": "command",
            "command": "~/.gemini/config/skills/git-guardrails/scripts/block-dangerous-git-antigravity.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

## Setup in Claude Code

### 1. Ask scope
Ask user: project (`.claude/settings.json`) or global (`~/.claude/settings.json`).

### 2. Script
Copy `scripts/block-dangerous-git.sh` to `.claude/hooks/block-dangerous-git.sh` and `chmod +x`.

### 3. Add to `.claude/settings.json`
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "command": ".claude/hooks/block-dangerous-git.sh"
      }
    ]
  }
}
```
