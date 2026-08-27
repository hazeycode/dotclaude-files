Portable coordinator workflow: global rules, lane skills, hooks, settings to keep the user in control and claude in his box.

## Install

Run from the project root. This overwrites whatever is already in `~/.claude`:

```bash
cp -R CLAUDE.md skills hooks templates agents ~/.claude/ && chmod +x ~/.claude/hooks/*.sh
```

That copies files but changes no settings. No hooks can take effect until you merge
`templates/settings.json` into `~/.claude/settings.json` yourself — each of the
blocks below covers a different gap, so skipping one leaves that gap open.
Starting fresh? `cp templates/settings.json ~/.claude/settings.json`.

Landings are reviewed in [VS Code](https://code.visualstudio.com) with
[Git Graph](https://marketplace.visualstudio.com/items?itemName=mhutchie.git-graph):

```bash
code --install-extension mhutchie.git-graph
```

Set `"LANE_REVIEW": "manual"` in the settings `env` block to skip that launch;
`skills/land-lane/SKILL.md` covers the other modes. The agent waits for your
merge either way.

## Security

This repo is public and installs into `~/.claude`, where its hooks run
unsandboxed and its skills and CLAUDE.md load as trusted instructions. Read
`hooks/`, `templates/settings.json`, the skills and the workspace template the
way you would read code you are about to run, because that is what they are.
Keep secrets out of the tracked `templates/settings.json`.

Four hooks ship with it; each file's header comment gives the attack it catches
and the gaps it does not:

| Hook | Effect |
|---|---|
| `enforce-lane-tier.sh` | denies a lane spawn that names no model |
| `guard-allowlisted-bash.sh` | prompts when an allowlisted command hides a substitution, an unmatched chain segment, or a write redirection |
| `refuse-sandbox-override.sh` | denies a Bash call asking to disable the sandbox, bar one named exception |
| `guard-exemption-writes.sh` | prompts on any write touching an exemption file, so the human grants the exemption rather than a lane |

The named exception is `skills/land-lane/open-review.sh`, which opens the
review window — a sandboxed process cannot reach launchd, so that one launch
has to leave the sandbox. It is exempted as the wrapper and never as `code`,
because `code` takes flags and a glob's `*` matches spaces, so any wildcarded
`code` pattern would also permit `--install-extension`. The wrapper takes one
argument, requires it to be an existing `*.code-workspace` file, and can run
nothing else. Delete it if you would rather have no override at all, and set
`"LANE_REVIEW": "manual"`.

The middle two first consult the project's own `.claude/bash-expansion-exempt`
and `.claude/sandbox-exempt` respectively (tracked, and live the moment you
clone) plus their untracked `.local` twins, which can add, veto or disown
entries. Read
those lists on any repo you didn't write. Writing a glob for one is a footgun
in two specific ways — anchor every pattern at the head, and never put `*`
inside an expansion that has not closed — and each hook header shows the exact
payload that gets through otherwise.

Two of those four resolve to a PROMPT rather than a refusal, as does the
`ask` rule on `~/.claude`, so who answers a prompt is load-bearing. In
[auto mode](https://code.claude.com/docs/en/permission-modes) a classifier
answers instead of you, and anything this repo turns into a prompt is then
decided without you seeing it — which is why `templates/settings.json` sets
`disableAutoMode` and `disableBypassPermissionsMode`. Merge the settings
selectively and that is the guarantee you drop. The sandbox is the exception
either way: it denies outright and asks nobody — except for declared
exemptions, which it honours without prompting either.

### Sandbox policy

Five blocks in `templates/settings.json` do the work:

| Block | Covers |
|---|---|
| `sandbox.filesystem` | bash and anything it runs |
| `permissions.deny` / `ask` | the file tools, which the sandbox does not cover |
| `sandbox.autoAllowBashIfSandboxed: false` | the switch that makes the rest apply |
| the two `permissions.disable*` gates | who answers a prompt, and that no session starts elevated |
| the four `hooks.PreToolUse` entries | the hooks above |

Sandboxing covers Bash commands and their child processes only. The Read and
Write tools ignore it, so the `permissions.deny` rules are what stop them, and
no settings file can undo a deny at any scope. While `autoAllowBashIfSandboxed`
is `true`, every sandboxed command is approved and nothing prompts at all — set
it to `false`, or the rest of this is inert.

Each project grants itself read access in one untracked line; writes inside it
are already allowed:

```jsonc
// <project>/.claude/settings.local.json   (gitignored)
{ "sandbox": { "filesystem": { "allowRead": ["."] } } }
```

`.` means the project root in a project file but `~/.claude` in the user file,
so the global settings cannot do this for you.

