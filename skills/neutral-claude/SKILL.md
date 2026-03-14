---
name: neutral-claude
description: >
  Orchestrates Claude context isolation via 3-step env scrub (env -i +
  temporary HOME + /tmp CWD) that ensures zero context leakage. INVOKE BEFORE
  spawning a Claude that MUST be uncontaminated — evals, design research,
  cold critique, or baseline comparisons. Cross-platform (Linux + macOS),
  no containers required. Triggers on 'neutral claude', 'naive claude',
  'isolated claude', 'clean claude instance', 'run without context',
  'uncontaminated claude'. (user)
---

# Neutral Claude

Run `claude -p` in full context isolation. The spawned Claude sees only its training weights and the three built-in skills (simplify, loop, claude-api) — no CLAUDE.md, no custom skills, no hooks, no project context.

## When to Use

- **Design research** — what verbs, patterns, or names would a Claude naturally produce?
- **Skill evaluation** — does a naive Claude understand a SKILL.md on first read?
- **Eval baselines** — "without skill" control group for A/B testing
- **Isolation testing** — verify a prompt works without your ecosystem's context
- **Cold critique** — get feedback uncoloured by your conventions

## When NOT to Use

- **Security sandboxing** — this is context isolation, not filesystem/process isolation. The spawned Claude can still read host files if it knows the paths. Use bwrap or containers for security.
- **Multi-turn conversations with memory** — each invocation is stateless
- **Testing your skills work** — you want context loaded for that, not stripped

## How It Works

Three mechanisms, all cross-platform (POSIX):

| Mechanism | What it blocks |
|-----------|---------------|
| `env -i` | All inherited env vars including `CLAUDECODE=1` (the nesting-detection var) |
| `HOME=<tmpdir>` with only `.credentials.json` | CLAUDE.md, settings.json, hooks config, skills directory, MCP config |
| `cd /tmp` | Project CLAUDE.md, git repo context, local `.claude/` directories |

The spawned Claude authenticates with your existing OAuth credentials (read-only copy) but has zero awareness of your configuration.

## Usage

The script lives at `~/.claude/skills/neutral-claude/../../scripts/neutral-claude.sh` — or more practically, find it relative to trousse:

```bash
SCRIPT="$(dirname "$(readlink -f ~/.claude/skills/neutral-claude/SKILL.md)")/../../scripts/neutral-claude.sh"
```

### Quick one-shot

```bash
neutral-claude.sh "What is the best way to structure a CLI?"
```

### With flags

```bash
neutral-claude.sh --max-turns 1 "Reply with only: hello"
neutral-claude.sh --max-turns 5 --dangerously-skip-permissions "Write and run a hello world script"
```

### Stdin mode (for long prompts or piping)

```bash
echo "Design a work tracker CLI" | neutral-claude.sh --stdin --max-turns 1
cat spec.md | neutral-claude.sh --stdin --max-turns 3
```

### From Claude Code (OuterClaude → InnerClaude)

```bash
# In a Bash tool call:
/path/to/neutral-claude.sh --max-turns 1 "Your prompt here"
```

The `env -i` scrub removes `CLAUDECODE=1`, so the inner Claude doesn't know it's nested. No launch resistance.

## What the Neutral Claude Sees

| Layer | Visible? |
|-------|----------|
| Global CLAUDE.md | No |
| Project CLAUDE.md | No |
| Custom skills (~/.claude/skills/) | No |
| Built-in skills (simplify, loop, claude-api) | Yes — compiled into Claude Code |
| Hooks | No |
| MCP servers | No |
| Host filesystem | Yes — context isolation, not security sandboxing |
| Your repos | Not discoverable (HOME is /tmp/xxx, CWD is /tmp) but readable if paths are guessed |

## Composing with Other Skills

| Skill | How they compose |
|-------|-----------------|
| **claude-survey** | Survey uses neutral-claude as its isolation backend instead of the mv/trap dance |
| **skill-forge** | Eval baselines — run prompts without the skill for A/B comparison |
| **sandbox** | Sandbox provides security isolation (containers/VMs); neutral-claude provides context isolation. Different threat models. |

## Anti-Patterns

| Don't | Do Instead | Why |
|-------|-----------|-----|
| Use Agent/Task tool for "naive" testing | Use this script via Bash tool | Subagents inherit full parent context |
| Pass `--system-prompt` and assume isolation | Use neutral-claude.sh | `--system-prompt` does NOT suppress CLAUDE.md loading |
| Use `--allowed-tools ""` for tool-free mode | Pass `--tools ""` via the script | `--allowed-tools` still offers tools; model burns turns trying to use them |
| Mount the real HOME | Let the script handle it | The whole point is a clean HOME |
