# myLab Agent Index

Workspace index for personal repos under `~/myLab/`. Each subdirectory is
usually its own git repo with independent build and test commands.

## Load order (all agents)

Read in order before exploring the filesystem:

1. This file (workspace index).
2. `~/myLab/initMe/agent/00-workspace.md`
3. `~/myLab/initMe/agent/01-core-behavior.md`
4. `~/myLab/initMe/agent/02-iterative-work.md`
5. Per-repo `AGENTS.md`, `CLAUDE.md`, or `README.md` in the repo you are editing.

Per-repo docs override this index for that repo.

## Projects

| Directory | Notes |
| --- | --- |
| `initMe/` | Dotfiles and bootstrap. Read `initMe/AGENTS.md` before editing scripts. Verify with `git ls-files '*.sh' \| xargs shellcheck`. |
| `mechanical-watch-ui/` | Vanilla HTML/JS. No build step; open `index.html` in a browser. |
| `apoorv-kulkarni.github.io/` | Jekyll site: `bundle install` then `bundle exec jekyll serve`. |
| `demo/` | Java/Spring Boot: `./mvnw spring-boot:run`, `./mvnw test`. |

## Personal_Practice

A separate practice repo may live at `~/Personal_Practice/` (not under `~/myLab/`).
No shared build system or test framework. Projects run standalone:

- `python/` - LeetCode-style scripts; run with `python <script>.py`
- `c++/` - compile with `g++`
- `rust/hello-world/` - `cargo run`
- `iOS/` - Swift playground, open in Xcode
- `apoorv-kulkarni.github.io/` - portfolio duplicate (Bootstrap 5)
- `dino.py` - reads `dataset1.csv` / `dataset2.csv` from repo root

## On-demand references

Load only when the task needs them:

| Topic | File |
| --- | --- |
| Coding standards and stack context | `~/myLab/initMe/agent/references/coding-reference.md` |
| Debugging method | `~/myLab/initMe/agent/references/debugging-method.md` |
| Post-PR cleanup | `~/myLab/initMe/agent/references/pr-cleanup-after-merge.md` |
| No em dashes in output | `~/myLab/initMe/agent/references/no-em-dashes.md` |

**Project workflow reminder:** check each repo's `Makefile`/`justfile` and CI
config (`.github/workflows/*.yml`) before suggesting commands.
