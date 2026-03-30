# Pre-Tool-Use Hook: Block Dangerous Commands

A Claude Code hook that intercepts and blocks potentially destructive bash commands before they execute.

## Features

- Blocks: `rm -rf`, `DROP TABLE`, `git push --force`, `TRUNCATE`, `DELETE FROM` without `WHERE`
- Logs every blocked attempt with timestamp, command, and project path
- Displays a clear warning message to Claude
- Minimal overhead — only intervenes on dangerous patterns
- Pure Bash, zero dependencies

## Installation (2 commands)

```bash
mkdir -p ~/.claude/hooks
cp pre-tool-use ~/.claude/hooks/ && chmod +x ~/.claude/hooks/pre-tool-use
```

That's it. The hook will automatically block dangerous commands in all future Claude Code sessions.

## How It Works

- Claude Code executes `~/.claude/hooks/pre-tool-use` before running any bash command.
- The hook receives the command as its first argument.
- If the command matches any blocklist pattern, the hook:
  1. Appends a log entry to `~/.claude/hooks/blocked.log`
  2. Prints a warning to stderr (visible to Claude)
  3. Exits with code 1, preventing the command from running
- Otherwise, exits 0 and the command proceeds.

## Blocking Rules

| Pattern | Reason |
|---------|--------|
| `rm -rf` | Recursive force deletion |
| `DROP TABLE` | Irreversible data loss |
| `git push --force` | History rewriting |
| `TRUNCATE` | Full table wipe |
| `DELETE FROM` without `WHERE` | Unintended full delete |

Detection is case-insensitive. For `DELETE FROM`, blocking only occurs if the command lacks a `WHERE` clause.

## Customization

To adjust patterns, edit the `pre-tool-use` script. Add or remove `elif` branches as needed.

## Logs

Blocked attempts are logged to `~/.claude/hooks/blocked.log` in JSON-friendly format:

```
[2026-03-30T18:40:00Z] BLOCKED: rm -rf /important/data | project: /home/user/project
```

## Uninstallation

```bash
rm ~/.claude/hooks/pre-tool-use
```

## License

MIT
