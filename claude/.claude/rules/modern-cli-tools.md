# Modern CLI Tools

Prefer these modern tools over their traditional counterparts. Fall back to the
traditional tool only if the modern one is unavailable or hits a problem.

| Instead of | Use | Notes |
|---|---|---|
| `grep` | `rg` (ripgrep) | For code-structure / pattern search, prefer the `ast-grep` skill (see ai-assistance.md). |
| `find` | `fd` | Simpler syntax, respects `.gitignore` by default. |
| `ls` | `eza` | `eza --tree` instead of `tree`. |
| `cat` | `bat` | Syntax highlighting + paging; use `bat --style plain` for clean output. |
| `cd` | `z` (zoxide) | Frecency-based jump. |
| `diff` / git pager | `delta` (git-delta) | Already wired into git via `core.pager`. |
| `top` | `btop` | |
| `man <cmd>` | `tldr <cmd>` | Quick example-driven usage. |
| `vim` | `nvim` (neovim) | |
| `pip` / `venv` | `uv` | Python packaging / env management. |
| docker CLI / git CLI (interactive) | `lazydocker` / `lazygit` | TUI front-ends. |
| `python -m json.tool` | `jq` / `jless` | `jc` to turn other commands' output into JSON. |

## Rules

- Default to the modern tool. Reach for the traditional one only as a fallback.
- For code pattern / AST search, `ast-grep` takes precedence over `rg` (see ai-assistance.md).
- These tools are installed via the project Brewfile; assume they exist on this
  workstation. On other hosts (Debian VMs, containers), check availability first.
