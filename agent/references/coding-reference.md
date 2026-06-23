# Coding reference

Cross-language standards and stack context. The behavioral core (interaction
guidelines, surgical edits, grounding, infra safety) lives in
`agent/01-core-behavior.md`.

## Project workflow

**Always check Makefile/CI config first** before suggesting commands:

1. Read Makefile/justfile for project workflows, build/test/lint commands
2. Read CI config (`.github/workflows/*.yml`) for test commands, environment, dependencies
3. Use project-defined targets (`make lint`, `make test`, `make verify`) instead of ad-hoc commands

**Why**: Project Makefiles run the same checks as CI, catch all issues at once, and respect project conventions.

## Languages & stack

Personal repos live under `~/myLab/`. Each project is usually independent
(no shared root build). Typical stacks in this workspace:

- **Go**: services, CLIs, tooling
- **Python**: scripting, automation
- **Java / Spring Boot**: `./mvnw test` when the project uses Maven Wrapper
- **Jekyll**: personal site (`bundle exec jekyll serve`)
- **Vanilla HTML/JS**: static frontends, no build step
- **HCL**: Terraform
- **YAML**: Kubernetes manifests, Helm charts
- **Shell**: zsh/bash scripts for automation

Infra tooling commonly available on a bootstrapped machine: Terraform (tfenv),
Vault, kubectl, k9s, minikube.

## Code standards

### Go

- Max line length: 130 chars (enforced by `golines` when configured)
- Import ordering: enforced by `gci` when configured
- Linting: `golangci-lint run` before committing when the project uses it
- CLI frameworks: `urfave/cli/v2` or `cobra`
- Testing: table-driven tests with `testify/require`, fail fast
- Naming: scope length correlates with variable name length; common abbreviations OK

### Python

- Use type hints for function signatures
- Prefer `pathlib` over `os.path`
- Use `dataclasses` or `pydantic` for structured data
- Virtual environments for project-specific deps

### Shell

- Always `set -euo pipefail` in scripts
- Quote all variables unless intentionally word-splitting
- Use `shellcheck` conventions

## Design principles (hierarchical priority)

1. **Make invalid states unrepresentable**: use types and enums to eliminate bugs at compile time; validate at boundaries
2. **Single Responsibility**: one clear purpose per type/function; small, modular, reusable components
3. **Code for humans**: readability over cleverness; hot paths may trade readability for performance with comments explaining why
4. **DRY**: duplication leads to silent divergence; extract common patterns
5. **Least Astonishment**: names and behavior match expectations; write docs/naming so behavior is predictable
6. **KISS**: minimize configuration, branching, complexity; remove non-varying config; simplify generics

## Error handling

### Go

- Always handle errors; never discard with `_`
- Use `github.com/cockroachdb/errors` for wrapping or `fmt.Errorf("context: %w", err)` depending on project convention
- Prefer returning errors over panicking; `panic` only for truly unrecoverable programmer errors
- Wrap errors with context at each layer: `errors.Wrap(err, "failed to fetch config")`
- Sentinel errors: `var ErrNotFound = errors.New("not found")`

## Dependency & module patterns

- Prefer standard `go.mod` / `go get` for dependencies; use `vendor/` when the project already vendors
- For private modules, confirm CI and local auth before assuming `GOPROXY` will resolve them
- Prefer small, focused packages over monolithic ones

## Tools & aliases

Installed via initMe bootstrap (`Brewfile`): `rg`, `jq`, `yq`, `gh`, `kubectl`,
`k9s`, `terraform`, `vault`.

**Shell aliases** (from `~/myLab/initMe/zshrc`): `k` (kubectl), `ll`, `uuid`/`uuid1`.

**Common commands**: `rg "pattern" --type go`, `kubectl get pods`, `k9s`,
`terraform plan`, `gh pr view`.

**Kubernetes shortcuts**: `k` (kubectl); add project-specific aliases in the
repo's docs if they exist.
