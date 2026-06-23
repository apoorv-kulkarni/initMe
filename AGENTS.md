# initMe Agent Instructions

Portable instructions for any AI agent editing this repository.

## Before changing anything

- Read `README.md`.
- Preserve separate macOS (`bootstrap.sh`) and Raspberry Pi (`bootstrap-pi.sh`)
  behavior. Do not assume one script works on the other OS.
- Preserve idempotency. Re-running bootstrap/install should remain safe.
- Do not execute `bootstrap.sh`, `bootstrap-pi.sh`, or `install-macos.sh`
  without explicit user permission.
- Prefer `--dry-run` when a script supports it.

## Verification

After editing shell scripts:

```bash
git ls-files '*.sh' | xargs shellcheck
```

CI runs the same check (`.github/workflows/shellcheck.yml`).

## Iterative Work

When repeatedly attempting a task:

1. Define an objective success check before making changes.
2. Inspect the current failure or state.
3. Make the smallest relevant change.
4. Run the success check again.
5. Continue only when the result shows measurable progress.

Stop when:

- Verification succeeds.
- Five attempts have been made (unless the user sets another limit).
- The same failure occurs twice without new evidence.
- Further progress requires broader scope, destructive action, running
  bootstrap/install scripts, or user input.

Never weaken tests, suppress errors, or alter unrelated behavior to obtain a
passing result. Report the final verification result and remaining blockers.

## Global agent rules

Generic methods (surgical edits, grounding, infra safety, documentation
standards) live in `agent/` and are installed to tool-specific adapters by
`install.sh`:

- **Cursor:** `~/.cursor/rules/*.mdc` (generated from `agent/manifest.tsv`)
- **Claude Code:** `~/.claude/CLAUDE.md` (index into `agent/`)
- **Workspace index:** `~/myLab/AGENTS.md` (when `~/myLab/` exists)

Per-repo `AGENTS.md` or `README.md` overrides workspace docs for that repo.
