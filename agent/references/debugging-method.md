# Debugging method

Domain-agnostic debugging habits. These are about *how to reason*, not about
any specific repo or tool. Apply them before reaching for trial-and-error.

## Verify the side effect, not the exit status

When a command or CI job exists to produce a side effect (write to a store,
register a record, converge a host, publish an artifact, rotate a secret), a
green check or a zero exit code is **not** proof it worked.

- Treat "the run succeeded" and "the run did the thing" as two separate claims.
- Verify the effect directly: read the value back, query the resulting state,
  diff the target. Do not infer success from the status badge.
- Be especially suspicious of workflows that can report success while their
  real work silently no-ops (wrong key names, skipped steps, swallowed errors).

## Matches a known-good sibling? Suspect the environment, not your config

When something fails but its configuration is identical to a sibling that
works, stop editing the config.

- Diff the failing thing against the known-good sibling first. If they match,
  the bug is almost certainly **outside** the file you are editing.
- Shift suspicion to external/environment state: capacity, quota, credentials,
  network zone/reachability, a dependency that changed underneath you, or
  clock/version skew.
- "This always worked and I changed nothing" usually means something *else*
  changed underneath. Find what moved, do not re-edit known-good config.

## On-disk correct is not the same as loaded

A correct config file does not mean a running process is using it.

- Many daemons read config only at **startup**. When a setting that looks
  correct on disk is not taking effect, prefer a **restart** over a reload,
  and compare process-start-time against config-mtime.
- When something is silently filtered, skipped, or absent, look for the
  **positive signal that should be present and isn't** (the log line, the
  registered attribute, the fingerprint) rather than waiting for an error
  that never comes. Absence of an error is not evidence of success.

## A failed command line may never have run your command

Shell-level failures abort before your command executes, so the output is
not a result about your subject. Empty output means "did not run", not
"not there".

- Unmatched globs (zsh `no matches found`), quoting errors, and unset
  variables under `set -u` all abort the whole line, so later `&&`-chained
  checks never execute.
- A negative result from a command you did not confirm actually ran is not
  evidence. Re-run the specific check in isolation before concluding.
- Especially dangerous when probing for existence ("is the file there?",
  "is it registered?"), where the abort is indistinguishable from a real
  negative.
