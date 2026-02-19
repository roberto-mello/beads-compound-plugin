---
description: Cross-platform shell scripting conventions
globs: "*.sh,**/*.sh"
---

# Shell Scripting Conventions

## find command compatibility

```bash
# WRONG - fails on GNU find (Linux)
find path -depth 1 -type d

# CORRECT - works on BSD (macOS) and GNU (Linux)
find path -mindepth 1 -maxdepth 1 -type d
```

- `-depth` is a flag (no argument) for depth-first traversal on GNU find
- `-depth 1` on GNU find interprets `1` as path argument -> error
- Both BSD find (macOS) and GNU find (Linux) support `-mindepth`/`-maxdepth`

Used in: `installers/install-opencode.sh`, `installers/install-gemini.sh`
