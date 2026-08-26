Portable coordinator workflow: global rules, lane skills, hooks, settings.

## Install

Run from the project root. This overwrites whatever is already in `~/.claude`:

```bash
cp -R CLAUDE.md skills hooks templates agents ~/.claude/ && chmod +x ~/.claude/hooks/*.sh
```

That copies files but changes no settings. Nothing takes effect until you merge
`templates/settings.json` into `~/.claude/settings.json` yourself. Read
[Sandbox policy](#sandbox-policy) first: it lists four blocks, each covering a
different gap. Skip one and that gap stays open.

Starting fresh? `cp templates/settings.json ~/.claude/settings.json`.

## Review interface

Landings are reviewed in [VS Code](https://code.visualstudio.com) with
[Git Graph](https://marketplace.visualstudio.com/items?itemName=mhutchie.git-graph):

```bash
code --install-extension mhutchie.git-graph
```

Set `"LANE_REVIEW": "manual"` in the settings `env` block to skip that launch.
Any tool that shows staged changes works, and the agent waits for your merge
either way.

## Security

This repo is public and installs into `~/.claude`, where its hooks run
unsandboxed and its skills and CLAUDE.md load as trusted instructions. Read
`hooks/`, `templates/settings.json`, the skills and the workspace template the
way you would read code you are about to run, because that is what they are.
Keep secrets out of the tracked `templates/settings.json`.

Three hooks ship with it:

| Hook | What it does |
|---|---|
| `enforce-lane-tier.sh` | refuses a lane spawn that names no model |
| `guard-allowlisted-bash.sh` | turns an allowlisted command containing `$( )` or backticks back into a prompt |
| `refuse-sandbox-override.sh` | refuses any Bash call asking to disable the sandbox |

In [auto mode](https://code.claude.com/docs/en/permission-modes) a classifier
answers prompts instead of you, so anything this repo turns into a prompt is
decided without you seeing it. The sandbox is the exception: it denies outright
and asks nobody.

### Sandbox policy

Four blocks in `templates/settings.json` do the work:

| Block | Covers |
|---|---|
| `sandbox.filesystem` | bash and anything it runs |
| `permissions.deny` | the file tools, which the sandbox does not cover |
| `sandbox.autoAllowBashIfSandboxed: false` | the switch that makes the rest apply |
| the three `hooks.PreToolUse` entries | the hooks above |

Sandboxing covers "Bash commands and their child processes" only. The Read and
Write tools ignore it, so the `permissions.deny` rules are what stop them. No
settings file can undo a deny, at any scope.

Each project grants itself read access in one untracked line:

```jsonc
// <project>/.claude/settings.local.json   (gitignored)
{ "sandbox": { "filesystem": { "allowRead": ["."] } } }
```

`.` means the project root in a project file but `~/.claude` in the user file,
so the global settings cannot do this for you. Reads are all a project needs;
writes inside it are already allowed.

While `autoAllowBashIfSandboxed` is `true`, every sandboxed command is approved
and nothing prompts at all. Set it to `false`, or the rest of this is inert.

## Working on this repo

Checked out at `~/Projects/.claude`, its `hooks/`, `skills/` and `agents/`
directories look to the harness like an installed `.claude` config, so it
write-protects them. Git then cannot rewrite those files and merges fail with
`unable to unlink old`. Check the repo out under any other name to avoid this.
