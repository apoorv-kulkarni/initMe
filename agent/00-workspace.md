# Workspace context

## Local layout

Personal repos live under `~/myLab/`. Each subdirectory is typically an
independent project with its own build and test commands.

Machine setup, shell config, and global agent rules live in `~/myLab/initMe/`
(symlinked into `~/.zshrc`, `~/.cursor/rules/`, `~/.claude/CLAUDE.md`, etc.).

## Read this first

Before `ls`-ing, `find`-ing, or grepping around to understand layout or
conventions:

1. Check the repo's own `AGENTS.md` / `README.md` / `CLAUDE.md`. It likely
   has the answer.
2. For work under `~/myLab/`, read `~/myLab/AGENTS.md` (workspace index).
3. Only then start poking at the filesystem.

If the answer isn't in those docs but should be (i.e. you find yourself
explaining the same thing a second time), offer to update the relevant doc
instead of just answering in chat.

## Knowledge promotion ladder (where does a new learning go?)

When something durable is learned in a session, pick its home by how broadly
useful it is. Rungs run from most throwaway to most permanent; promote a
learning up a rung only once it has earned the wider scope:

1. **This chat only** - a one-off fact you will not reuse. Do nothing.
2. **Personal notes** - durable but personal, never committed. The default
   home for facts about your environment (conventions, gotchas, runbooks).
3. **A repo's committed rule file** - a repeatable, file-scoped *convention*
   you would want in every session for that repo (e.g. `.cursor/rules/*.mdc`
   under that project). Scoped to one repo under `~/myLab/`.
4. **Personal dotfiles rules** - a generic *method or behavior*, not a domain
   fact, that applies in any repo or stack. Lives in `~/myLab/initMe/agent/`
   and is installed to tool-specific adapters by `install.sh`.

Rule of thumb: **facts stay personal (rungs 1-2); methods become rules
(rungs 3-4).** Never commit employer-specific or private domain facts into
public dotfiles.
