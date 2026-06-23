# Iterative work

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
- Further progress requires broader scope, destructive action, or user input.

Never weaken tests, suppress errors, or alter unrelated behavior to obtain a
passing result. Report the final verification result and remaining blockers.

## Cursor

In Cursor Agent chat, use `/loop` only with explicit success and stop
conditions. Never start an unbounded loop.
