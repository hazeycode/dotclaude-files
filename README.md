Portable coordinator workflow: global rules, lane skills, hooks, settings.

Install into the user global dir (run from the project root):
**Overwrites what's
already there!**
```bash
cp -R CLAUDE.md settings.json skills hooks templates agents ~/.claude/ && chmod +x ~/.claude/hooks/*.sh
```

The default review interface is [VS Code](https://code.visualstudio.com) with
the [Git Graph](https://marketplace.visualstudio.com/items?itemName=mhutchie.git-graph)
extension:

```bash
code --install-extension mhutchie.git-graph
```

Prefer other tooling? `"LANE_REVIEW": "manual"` in the settings `env` block
skips the VS Code launch — the staged merge reviews in any tool that shows
staged changes and the agent watches for a merge.

## Security

This repo is **public** and installs to `~/.claude/`, where its hooks run
unsandboxed on every tool call and its skills/CLAUDE.md load as trusted model
instructions. Review `hooks/`, `settings.json`, the skills, and the workspace
template with the scrutiny of executable code — a change to any of them is code
running as you. Keep secrets out of the tracked `settings.json`; machine-local
config and credentials belong in `settings.local.json` (gitignored).

