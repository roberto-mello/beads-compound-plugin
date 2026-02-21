# GitHub Release Checklist

When asked to create a GitHub release, run ALL steps in order. Do not tag or push until pre-release checks pass.

## 1. Sync

```bash
git pull --rebase
```

## 2. Verify versions are set correctly

- `plugins/beads-compound/.claude-plugin/plugin.json` — must have the target version
- `.claude-plugin/marketplace.json` — must match `plugin.json` version exactly

Fix either file if they don't match before continuing.

## 3. Run pre-release checks (MUST PASS before tagging)

```bash
bash scripts/pre-release-check.sh
```

This replicates the CI `verify-release` job locally:
- Version consistency between `plugin.json` and `marketplace.json`
- Conversion outputs generated (OpenCode + Gemini)
- Component counts (25+ commands, 28+ agents, 15+ skills)
- Source files present
- Compatibility tests pass

**Do not proceed if any check fails.**

## 4. Push commits

```bash
git push
```

## 5. Tag and release

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
gh release create vX.Y.Z --title "vX.Y.Z" --generate-notes
```

## 6. Verify CI passes

```bash
gh run list --limit 5
# If failed: gh run view <run-id> --log-failed
```

## If CI fails post-release

Do NOT delete and recreate the tag. Bump to a patch version, fix, and release that instead.

## Keeping pre-release checks in sync with CI

`scripts/pre-release-check.sh` mirrors the `verify-release` job in `.github/workflows/test-installation.yml`.

**When modifying either file, always update the other.** Both files have a `SYNC:` comment pointing to each other as a reminder. If CI adds a new check, add it to the script. If the script adds a new check, add it to CI.

## Key facts

- `marketplace.json` uses `"name"` field (not `"id"`) per the Claude Code plugin spec
- CI query: `.plugins[] | select(.name == "beads-compound") | .version`
- Both `plugin.json` and `marketplace.json` versions must match or CI fails
