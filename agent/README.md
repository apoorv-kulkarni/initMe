# Agent rules (canonical source)

Plain Markdown agent instructions. **Edit these files**, not the installed
adapters under `~/.cursor/rules/` or `~/.claude/`.

`install.sh` (and `bootstrap.sh`) run `scripts/build-agent-adapters.sh` to
install tool-specific adapters:

| Output | Source |
| --- | --- |
| `~/.cursor/rules/*.mdc` | `agent/*.md` + `agent/manifest.tsv` (YAML frontmatter added at install; stale rules pruned via `.initme-managed-rules`) |
| `~/.claude/CLAUDE.md` | `adapters/claude-global.md` |
| `~/myLab/AGENTS.md` | `templates/mylab-AGENTS.md` (when `~/myLab/` exists) |
| `~/myLab/CLAUDE.md` | `adapters/mylab-CLAUDE.md` (copied, not symlinked) |

## Layout

```
agent/
├── manifest.tsv           # Cursor-only metadata (alwaysApply, description)
├── 00-workspace.md
├── 01-core-behavior.md
├── 02-iterative-work.md
└── references/            # on-demand (alwaysApply: false in Cursor)
```

## Adding a rule

1. Add or edit a `.md` file under `agent/`.
2. Add a row to `manifest.tsv` if Cursor should load it.
3. Run `bash install.sh` to regenerate adapters.
