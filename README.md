Portable coordinator workflow: global rules, lane skills, hooks, settings to keep the user in control and claude in his box.

## What it does

Delegated work runs in a background agent with its own git worktree and branch —
a *lane*. Two skills carry the checklists: `spawn-lane` builds the brief,
`land-lane` verifies the result and stages it for you.

```
you: "do X"
  → coordinator spawns a lane (own worktree, own branch)
  → lane works, runs its scoped gates, commits, reports
  → coordinator re-runs the full gate battery on the lane tip and PINS it
  → coordinator stages `git merge --no-ff --no-commit` on main
  → YOU review the staged merge and author the merge commit
  → coordinator retires the lane, or hands it the next brief
```

**The last step is the one only you can do.** The coordinator commits on lane
branches; the landing merge on the target branch is always yours. At the review
window:

| You want to | Do this |
|---|---|
| accept | `git commit` — the message is prefilled in `.git/MERGE_MSG`; edit and save |
| fix something first | edit the files; your edits become part of the merge commit you author |
| reject, or ask for changes | say so in chat — the coordinator preserves your edits as a patch, then aborts |

Nothing runs on a timer you have to beat: the watcher polls for an hour and then
asks rather than re-arming.

## Install

Needs `git`, `jq`, and bash 3.2 (stock macOS is fine). **`jq` is not optional** —
without it the four hooks fail in two different directions: `enforce-lane-tier`
and `refuse-sandbox-override` deny (closed), `guard-allowlisted-bash` and
`guard-exemption-writes` go silent (open). Nothing on screen tells you which.

Run from the repo root:

```bash
cp -R CLAUDE.md skills hooks templates agents ~/.claude/ && chmod +x ~/.claude/hooks/*.sh ~/.claude/skills/land-lane/*.sh
```

`cp -R` **merges**: it overwrites file by file and never deletes. A file renamed
or removed in a later version stays installed and keeps loading, so re-running
the copy is not a clean install — `doctor.sh` sweeps for those orphans.

That copies files but changes no settings. No hooks can take effect until you merge
`templates/settings.json` into `~/.claude/settings.json` yourself — each of the
blocks covers a different gap, so skipping one leaves that gap open.

Starting fresh? `cp templates/settings.json ~/.claude/settings.json`.

Then check the install:

```bash
bash doctor.sh
```

It compares every installed file against this repo, sweeps for orphans, asserts
each settings block is present, and drives all four hooks with payloads they
**must** refuse and payloads they **must** pass through — because a hook that
never fires looks exactly like one that always passes. `bash doctor.sh --repo`
tests this working tree instead, for before you install or after you edit a hook.
Every check prints its own verdict; exit 0 means all of them passed.

### Per project

Each project grants itself read access in one untracked line. Without it the
agent gets "Operation not permitted" on the project's own files:

```bash
mkdir -p <project>/.claude
cp templates/settings.local.json <project>/.claude/settings.local.json
```

`.` means the project root in a project file but `~/.claude` in the user file, so
global settings cannot do this for you. Add the path to the project's
`.gitignore` — an untracked file there fails land-lane's clean-checkout precheck.

### Review tool

Landings are reviewed in [VS Code](https://code.visualstudio.com) with
[Git Graph](https://marketplace.visualstudio.com/items?itemName=mhutchie.git-graph):

```bash
code --install-extension mhutchie.git-graph
```

`task.allowAutomaticTasks` must also be **on in USER settings**, once per
machine — it is application-scoped, and an untrusted workspace suppresses the
window's tasks silently.

`templates/settings.json` sets `"LANE_REVIEW": "vscode"` in its `env` block;
change it to `"manual"` to skip that launch and view the staged merge with your
own tool. `skills/land-lane/SKILL.md` covers both. The agent waits for your merge
either way.

## Security

This repo is public and installs into `~/.claude`, where its hooks run
unsandboxed and its skills and CLAUDE.md load as trusted instructions. Read
`hooks/`, `templates/settings.json`, `doctor.sh`, the skills and the workspace
template the way you would read code you are about to run — that is what they
are. Keep
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

Watch them work before trusting them: `bash doctor.sh` drives each one with
payloads it must refuse and payloads it must wave through, and prints the
decision it actually got.

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

## Troubleshooting

`bash doctor.sh` answers most of these before you have to ask.

| Symptom | Cause |
|---|---|
| "Operation not permitted" on the project's own files | no `<project>/.claude/settings.local.json` — see [Per project](#per-project) |
| A guard never prompts, or never denies | the settings were not merged, or `jq` is missing (two hooks go silent without it) |
| doctor says an installed file DIFFERS | the installed copy is what runs, not this repo. Re-run the install `cp`, then doctor again |
| Everything is auto-approved anyway | `sandbox.autoAllowBashIfSandboxed` is not `false`, which makes every other block inert |
| A prompt gets answered without you | auto mode — `disableAutoMode` was not merged, so a classifier answers instead of you |
| The review window opens empty, or not at all | `mhutchie.git-graph` missing, or `task.allowAutomaticTasks` off in USER settings, or the workspace is untrusted (fails silently) |
| `code -n` exits 0 and no window appears | a sandboxed child cannot reach launchd. That is why `open-review.sh` exists — the one `dangerouslyDisableSandbox` call in the workflow |
| An edit to a skill has no effect on a running session | skills inject once per session and never reload — the session keeps the copy from its first load until it restarts. Editing skills is the work in this repo, so this bites often |
| doctor WARNs that `templates/…` is unreadable | expected when doctor itself runs sandboxed: `~/.claude/templates` is not on the sandbox read list. Nothing loads templates at runtime |