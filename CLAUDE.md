# Global working rules

Portable, project-agnostic coordinator workflow. Project-specific facts (gates,
hashes, file names) live in each project's own CLAUDE.md — nothing here should
need editing when a project changes.

## Coordination model

- **The main session coordinates; lanes do the work.** One worktree-isolated
  agent per independent piece; keep coordinator turns short. Anything you could
  just write yourself, write — a lane costs a worktree, the project context,
  and a merge.
- **Two skills carry the checklists: `spawn-lane`** (model tier, brief, region
  ownership, scoped gates, report contract) **and `land-lane`** (verify, stage
  the merge, then WATCH — **the HUMAN authors the landing merge on main; the
  coordinator commits only on lane branches**. Every lane — and every change
  the coordinator authors itself, which becomes a self-lane branch and lands
  through the same skill; no exceptions).
  Load the skill at those two moments; don't work from memory of this file.
- **Cap concurrent lanes (~4)** unless measurement says more. Exclusive
  resources (GPU, benchmarks) get one lane at a time, or a lock. **Count the
  cap from the LIVE AGENT LIST, never your own tally** — a lane can report
  complete and stay registered as running.
- **Lanes read sibling repos freely, modify them never** — cross-repo edits and
  API-break sequencing are the coordinator's.
- **Dead lanes respawn fresh from a checkpoint; idle lanes get a nudge;
  FINISHED lanes get killed.** Transcript replay is expensive — lanes commit a
  running state-of-play (measured / ruled out / half-built / next) so a fresh
  lane picks up from disk.
- **Prune dead worktrees routinely** — at every retire, and sweep whenever the
  registry grows: a branch fully merged into the target with no tracked
  modifications loses its worktree and branch; anything else is surfaced,
  never forced past tracked changes. Every registered worktree becomes a line
  of fixed context in every future session's environment block, so debris
  taxes each turn of each session.
- **BAN UNBOUNDED WAIT-LOOPS IN EVERY BRIEF; bound the retries and exit.** A
  lane polling `until` for what can no longer arrive reports complete yet sits
  registered as running — burning a cap slot, firing a notification per expiry.
  One cost three hours of a slot, caught only because the live list disagreed
  with the tally.
- **Briefs carry established findings** — never send a lane to re-read a long
  plan; extend plans, don't multiply them. **Never restate what a committed
  plan, report, or log already records** — in briefs, task descriptions, and
  reports alike: cite the file and section plus the load-bearing numbers. The
  owning doc carries the substance once; restating it pays twice, at frontier
  output prices.
- **Ask vs decide:** the coordinator decides anything derivable from code,
  docs, or measurement; the human rules on goals, trade-offs, and anything
  moving a baseline. Rulings are short option quizzes with a recommendation,
  recorded in the owning doc as they land, never re-litigated — a recorded
  ruling is load-bearing until the human moves it.

## Verification discipline

Checks are cheap; churn is not — mistakes, not verification, are the token cost.

- **Run the check on the tree YOU built**; never quote a literal from a plan,
  doc-comment, or brief when the artifact itself can be read.
- **Quote the exit codes you actually saw** — never pipe a merge or gate
  through `tail`/`head` in a `&&` chain; it launders the exit code. Capture
  `$?` explicitly.
- **Inspect visual A/Bs with your own eyes** — metrics under
  auto-exposure/auto-gain read a defective frame as healthy. Look at both
  images before reporting or shipping.
- **Attribution before acceptance**: two changes with one reading tell you
  nothing. One reading per change plus the combination, on one tree, baseline
  reproduced first.
- **Controls must scramble exactly what the mechanism claims to derive** —
  write the single term down before running one; a control over a composite
  proves only the composite matters. Run the amplitude-matched
  pattern-destroying control before crediting a derivation.
- **State the sampling scale with every number** — cell size / window /
  resolution, or the number means nothing.
- **Never edit a target, reference, or threshold to make a number agree**;
  never harden a gate around current output.
- **Concurrent machines: interleave A/B arms; report ratios, not absolute
  times.**
- **Measure over the SHORTEST statistically valid span, and prove it** — a
  long window is unexamined cost, not rigour. Split the sample: agreeing
  halves prove the span; disagreeing halves mean it must grow. Interleave arms
  in PAIRS and stop when separation exceeds spread — never a habitual rep
  count. An inherited window is not binding: re-measure the baseline as your
  own arm and the span is yours, because acceptance is the RATIO.
- **Watch every new gate or probe go RED on purpose before believing it** —
  and a gate must PRINT its verdict; silence is inconclusive, never a pass.
- **A DELIBERATE-RED ARM HAS A SAMPLE SIZE — state it, and why the arm could
  have failed.** A green deliberate-red usually means the fixture was too
  small to bite: a dropped cache-key field passed at 6 items and failed at 40;
  an identity fixture too coarse to hold the defect passed while testing
  exactly that defect. Both caught only because the lane distrusted its own
  pass.
- **A check must be as WIDE as the claim it supports.** A probe proving a
  cache KEY moves says nothing about the PAYLOAD; a share divided by a
  denominator it never accumulates prints 0.0% while looking armed. The gap
  between verified and concluded is where wrong answers live — and it is the
  READER's error as often as the probe's.
- **When a result surprises, audit the instrument before the mechanism** —
  blind probes, noise-limited gates, and void controls produce confident wrong
  verdicts.
- **Prove the problem before building the fix** — a suite that verifies a
  mechanism says nothing about whether the mechanism was needed. Measure the
  friction, or reproduce the failure, before writing the cure.
- **A containment probe must never carry a sandbox override** — its result is
  void. Four probes in one session read clean because the override was set.
- **Report what you actually saw.** A negative result that kills a design
  cheaply is the most valuable thing a lane can produce.

## Code hygiene

- **No golden-path switches.** Attribution levers (env vars, flags) die at
  acceptance with a no-diff proof; modes, pins, and off-by-default features
  survive. In the shipped path there is no toggle.
- **A code-changing lane tidies the regions it touches** (stale comments,
  lying docs, dead decls — same evidence bar as any deletion) and reports the
  simplification candidates it saw but did not perform. Never a licence to
  refactor past the brief.
- **Keep shared context lean continuously** — compress in the same edit that
  grows it, without information loss, across responses, code, comments, docs,
  and memories; clean stale things as you go. Every lane loads the project file
  in full every time.
- **Plans state current truth: DELETE superseded content, don't annotate it
  dead** — a staleness banner makes every reader parse both eras. Grep citing
  sites before cutting; append-only records (ledgers, signed entries) are
  history, not dead — they stay.

## Sandbox and local settings

- **A denial is policy, not an obstacle: report it and stop.** Never disable
  the sandbox to get past one — the only overrides are a deliberate test OF the
  sandbox, or an action outside the boundary the human explicitly asked for
  (installing to `~/.claude`).
- **The exemption lists are read-only to you.** `.claude/sandbox-exempt`,
  `.claude/bash-expansion-exempt` and their `.local` twins are the glossary of
  what already runs unprompted — read them before shelling out (file tool, not
  `cat`: a Bash mention prompts). They are honoured with no prompt at all, so
  adding a line IS the grant: a gate needing `dangerouslyDisableSandbox` or a
  command carrying `$( )` is a REQUEST — report the exact glob, the command,
  and why nothing weaker works. Never write the line; never hunt a phrasing
  that slips past a guard.
- **Reads stop at the repo; writes stop at the repo and `$TMPDIR`.** A project
  becomes readable only through its OWN untracked
  `.claude/settings.local.json` — `{"sandbox":{"filesystem":{"allowRead":["."]}}}`.
  `.` means the project root in project scope but `~/.claude` in user scope, so
  the global baseline cannot grant it. "Operation not permitted" on a project's
  own files means that file is missing.
- **`skills/`, `hooks/`, `agents/` and `~/.claude` refuse bash writes at every
  scope** — no config lifts it. Edit them with the file tools, which go through
  permissions instead; a git operation that rewrites those paths fails with
  `unable to unlink old`.
- **State goes in `<project>/.claude/state/`, never `~/.claude`.** Task notes,
  scratch and state-of-play belong to the project, which is writable. Keep the
  path gitignored — an untracked file there fails land-lane's clean-checkout
  precheck. `~/.claude` is READ-ONLY and only its installed artifacts
  (`CLAUDE.md`, `skills/`, `agents/`, `hooks/`, `settings.json`) are readable
  at all; everything else there, including transcripts and credentials, is
  denied.

## Git in a multi-lane world

- Never bare `git stash`/`stash pop` (the stack is global across worktrees) —
  WIP commits, or `stash push -u -m <tag>` + `apply` by SHA.
- Never `git add -A`, `checkout`, `reset`, `restore`, or `clean` outside your
  own worktree — lanes run concurrently.
- A lane commits ONLY to its own branch (check `git branch --show-current`
  before the first commit); never touch main from a lane; never push unasked.
- Commit early, often, and before any `git checkout`.
- **Keep commit messages short.** One line for most commits. Add a few lines of
  body only for a large or surprising change. Never restate what the diff, the
  README, or a committed doc already says — the reader has all three.

## Context economy

- **Grep first, then read the part you need** — reads dominate context cost,
  and a big early read is re-paid every turn after.
- **Never `cd`; work from your persistent cwd** — compound `cd … && …` is the
  largest single source of tool errors in sandboxed worktrees, and triggers
  permission prompts. The Bash cwd persists across calls and a lane starts in
  its own worktree, so relative paths just work; absolute paths only to reach
  another tree (`git -C <path>`).
- **Batch background work** — every background completion replays the whole
  context as a fresh turn, so N small background tasks cost N replays. Run
  short probes foreground in one compound command (per-step exit codes
  captured); reserve background for genuinely long runs, grouped so
  completions cluster; never poll for what the harness will notify.
