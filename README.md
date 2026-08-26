Portable coordinator workflow: global rules, lane skills, hooks, settings.

Install into the user global dir (run from the project root):
**Overwrites what's
already there!**
```bash
cp -R CLAUDE.md skills hooks templates agents ~/.claude/ && chmod +x ~/.claude/hooks/*.sh
```

This does not touch your `~/.claude/settings.json`. The hooks only run once
they are registered there, so merge `templates/settings.json` into your own
settings by hand — at minimum the `hooks` block; the `permissions` and
`sandbox` blocks are the recommended defaults for the workflow. Starting
fresh? `cp templates/settings.json ~/.claude/settings.json`.

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
unsandboxed on every matched tool call and its skills/CLAUDE.md load as
trusted model instructions. Review `hooks/`, `templates/settings.json`, the
skills, and the workspace template with the scrutiny of executable code — a
change to any of them is code running as you. Keep secrets out of the tracked
`templates/settings.json`; machine-local config and credentials belong in
`settings.local.json` (gitignored).

