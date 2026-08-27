Portable coordinator workflow: global rules, lane skills, hooks, settings to keep the user in control and claude in his box.

## Install

Run from the project root. This overwrites whatever is already in `~/.claude`:

```bash
cp -R CLAUDE.md skills hooks templates agents ~/.claude/ && chmod +x ~/.claude/hooks/*.sh
```

That copies files but changes no settings. No hooks can take effect until you merge
`templates/settings.json` into `~/.claude/settings.json` yourself — each of the
blocks covers a different gap, so skipping one leaves that gap open.

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
way you would read code you are about to run — that is what they are. Keep
secrets out of every `settings.json` `env` block (the tracked template
included): the file is sandbox-`allowRead` and `grep`/`head`/`tail` are
Bash-allowlisted, so an agent reads it unprompted, and `permissions.deny
Read(...)` binds only the Read tool, not Bash. Put secrets in the environment
or a file the sandbox cannot read.

Four hooks ship with it; each file's header gives the attack it catches and the
gaps it does not — read them:

| Hook | Effect |
|---|---|
| `enforce-lane-tier.sh` | denies a lane spawn that names no model |
| `guard-allowlisted-bash.sh` | prompts when an allowlisted command hides a substitution, an unmatched chain segment, or a write redirection |
| `refuse-sandbox-override.sh` | denies a Bash call asking to disable the sandbox, bar one named exception |
| `guard-exemption-writes.sh` | prompts on any write to an exemption file, so the human grants the exemption, not a lane |

The one sandbox-override exception is the wrapper `skills/land-lane/open-review.sh`
(opening the review window needs launchd, which the sandbox blocks). It is
exempted as the wrapper, never as `code` — `code` takes flags and a glob's `*`
matches spaces, so any wildcarded `code` pattern would also permit
`--install-extension`; the wrapper accepts one existing `*.code-workspace` file
and nothing else. Delete it and set `"LANE_REVIEW": "manual"` for no override.

The middle two first consult the project's tracked `.claude/bash-expansion-exempt`
/ `.claude/sandbox-exempt` (live on clone) plus untracked `.local` twins that
add, veto or disown entries — read those lists on any repo you didn't write.
Writing a glob is a footgun two ways: anchor every pattern at the head, and
never put `*` inside an unclosed expansion (each hook header shows the payload
that escapes otherwise).

Two of the four resolve to a PROMPT, as does the `ask` on `~/.claude` — so who
answers is load-bearing. In [auto mode](https://code.claude.com/docs/en/permission-modes)
a classifier answers instead of you, which is why `templates/settings.json` sets
`disableAutoMode` and `disableBypassPermissionsMode`; merge the settings
selectively and you drop that guarantee. The sandbox is the exception: it denies
outright and asks nobody, honouring declared exemptions without a prompt either.

### Sandbox policy

Six settings in `templates/settings.json` do the work:

| Block | Covers |
|---|---|
| `sandbox.filesystem` | bash and anything it runs |
| `permissions.deny` / `ask` | the file tools, which the sandbox does not cover |
| `sandbox.autoAllowBashIfSandboxed: false` | the switch that makes the rest apply |
| the two `permissions.disable*` gates | who answers a prompt, and that no session starts elevated |
| the four `hooks.PreToolUse` entries | the hooks above |
| `sandbox.network.strictAllowlist: true` | egress denied by default; add hosts to `allowedDomains` |

Sandboxing covers Bash and its children only; the Read/Write tools ignore it, so
`permissions.deny` is what stops them and no settings file undoes a deny at any
scope. `autoAllowBashIfSandboxed` must be `false` or every sandboxed command is
auto-approved and the rest is inert. Each project grants itself read access in
one untracked line (writes inside are already allowed):

```jsonc
// <project>/.claude/settings.local.json   (gitignored)
{ "sandbox": { "filesystem": { "allowRead": ["."] } } }
```

`.` means the project root in a project file but `~/.claude` in the user file,
so global settings cannot do this for you.