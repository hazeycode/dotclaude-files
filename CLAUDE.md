# Global working rules

Portable, project-agnostic coordinator workflow. Project-specific facts (gates,
hashes, file names) stay in each project's own CLAUDE.md — nothing here should
need editing when a project changes.

## Coordination model

- **The main session coordinates; lanes do the work.** Spawn a worktree-isolated
  agent per independent piece of work; keep coordinator turns short. Anything you
  could just write yourself, write — a lane costs a worktree, the project context,
  and a merge.
- **Two skills carry the step-by-step checklists: `spawn-lane`** (model tier, brief
  construction, region ownership, scoped gates, report contract) **and `land-lane`**
  (skeptical read, explicit-exit-code merge, re-gate on the merged tree, golden
  values, visual inspection, recording). Load the matching skill at those two
  moments rather than working from memory of this file.
- **Cap concurrent lanes (~4)** unless measurement says the machine takes more.
  Exclusive resources (GPU, benchmarks) get one lane at a time, or a lock.
  **Count the cap from the LIVE AGENT LIST, never from your own tally** — a lane
  can report complete and stay registered as running.
- **A lane is spawned isolated and VERIFIES it on arrival** (cwd inside a
  worktree, branch not main); if unisolated it hand-builds a worktree and works
  by absolute path — never via worktree commands that assume a free cwd.
- **Lanes read sibling repos freely, modify them never** — cross-repo edits and
  API-break sequencing belong to the coordinator.
- **Dead lanes respawn fresh from a checkpoint; idle lanes get a nudge; FINISHED
  lanes get killed.** Resuming by transcript replay is expensive — require lanes to
  commit a running state-of-play (measured / ruled out / half-built / next) so a
  fresh lane can pick up from disk.
- **BAN UNBOUNDED WAIT-LOOPS IN EVERY BRIEF; bound the retries and exit.** A lane
  polling with `until` for something that can no longer arrive finishes its work,
  reports complete, and still sits registered as *running* — burning a cap slot and
  firing a notification per expiry. One cost three hours of a slot before it was
  spotted, and only because the live list disagreed with the tally.
- **Briefs carry established findings** — never send a lane to re-read a long
  plan document. Extend plans, don't multiply them.
- **Ask vs decide:** the coordinator decides anything derivable from the code,
  the docs, or a measurement; the human rules on goals, trade-offs, and anything
  that moves a baseline. Rulings are presented as short option quizzes with a
  recommendation, recorded in the owning doc at the moment they land, and never
  re-litigated — a recorded ruling is load-bearing until the human moves it.
- **Gate scoping is the coordinator's job.** Pick the lane's verification list
  from its diff surface at brief time; the full suite runs once at merge as the
  safety net. Not every lane runs every gate.

## Model selection for lanes

- **Capability floor beats cost.** Never let price push work to a model unlikely
  to perform it. If output tokens are expensive, the rule is "be concise without
  degrading performance", not "use a weaker model".
- **Sonnet when the brief carries the judgement** (mechanical edits, applying a
  decision, a specified sweep). **The frontier model when the lane must decide
  what "correct" means, could invalidate baselines, or when the instrument can
  fail silently.** Haiku is retired for lanes: a pilot misquoted a number in its
  one interpretation sentence.

## Verification discipline

- **Run the check on the tree YOU built**; never quote a literal from a plan,
  doc-comment, or brief when the value can be read from the artifact itself.
- **Quote the exit codes you actually saw.** Never pipe a merge or gate through
  `tail`/`head` inside a `&&` chain — it launders the exit code; capture `$?`
  explicitly.
- **Inspect visual A/Bs with your own eyes.** Metrics under auto-exposure/auto-
  gain can read a defective frame as healthy. Look at both images before
  reporting or shipping.
- **Attribution before acceptance**: two changes landing together with one
  reading tell you nothing. One reading per change plus the combination, on one
  tree, baseline reproduced first.
- **Controls must scramble exactly what the mechanism claims to derive** — write
  the single term down before running one; a control over a composite proves only
  the composite matters. Run the amplitude-matched pattern-destroying control
  before claiming a derivation did the work.
- **State the sampling scale with every number** — a measurement means nothing
  without its cell size / window / resolution.
- **Never edit a target, reference value or gate threshold to make a number
  agree**, and never harden a gate around current output.
- **Concurrent machines: interleave A/B arms; report ratios, not absolute times.**
- **Measure over the SHORTEST span that is statistically valid, and prove it is** —
  a long window is not rigour, it is unexamined cost. Split your sample in half and
  report both halves: agreeing halves prove the span was long enough; disagreeing
  halves mean the series is not stationary there and it must grow. Interleave arms
  in PAIRS and stop when the separation exceeds the spread — never a fixed rep count
  out of habit. An inherited window is not binding: re-measure the baseline as your
  own arm and the span becomes yours to choose, because acceptance is the RATIO.
- **Watch every new gate or probe go RED on purpose before believing it** — and
  a gate must PRINT its verdict; silence is inconclusive, never a pass.
- **A DELIBERATE-RED ARM HAS A SAMPLE SIZE — state it, and say why the arm could
  have failed.** A green deliberate-red usually means the fixture was too small to
  bite, not that the guard works: a dropped cache-key field passed at 6 items and
  only failed at 40; an identity fixture too coarse to hold the defect passed while
  testing exactly that defect. Both were caught only because the lane distrusted
  its own pass.
- **A check must be as WIDE as the claim it is used to support.** A probe that
  proves a cache KEY moves says nothing about the PAYLOAD; a share divided by a
  denominator it does not accumulate prints 0.0% while looking armed. The gap
  between what was verified and what gets concluded is where wrong answers live —
  and it is the READER's error as often as the probe's.
- **When a result surprises, audit the instrument before the mechanism** —
  blind probes, noise-limited gates, and void controls all produce confident
  wrong verdicts.
- **Report what you actually saw.** A negative result that kills a design cheaply
  is the most valuable thing a lane can produce.

## Code hygiene

- **No golden-path switches.** Attribution levers (env vars, flags) die at
  acceptance with a no-diff proof; modes, pins, and off-by-default features
  survive. If it's in the shipped path, there is no toggle for it.
- **A code-changing lane also tidies the regions it touches** (stale comments,
  lying docs, dead decls — same evidence bar as any deletion) and reports the
  simplification candidates it saw but did not perform. Never a licence to
  refactor past the brief.
- **Keep shared context lean continuously** — compress in the same edit that
  grows it. Every lane loads the project file in full every time.
- **Plans state current truth: DELETE superseded content, don't annotate it
  dead.** A "this section is stale" banner makes every future reader parse both
  eras. Verify citing sites (grep) before cutting; append-only records (ledgers,
  signed entries) are history, not dead — they stay.

## Git in a multi-lane world

- Never bare `git stash`/`stash pop` (the stack is global across worktrees);
  use WIP commits, or `stash push -u -m <tag>` + `apply` by SHA.
- Never `git add -A`, `checkout`, `reset`, `restore` or `clean` outside your
  own worktree — lanes run concurrently.
- A lane commits ONLY to its own branch; check `git branch --show-current`
  before the first commit. Never touch main from a lane; never push unasked.
- Commit early, often, and before any `git checkout`.

## Context economy

- **Grep first, then read the part you need** — reads dominate context cost, and
  a big early read is re-paid every turn after.
- **Absolute paths; do not `cd`** — compound `cd … && …` is the largest single
  source of tool errors in sandboxed worktrees.
- **Condense and simplify before final commit, without information loss** — chat
  responses, code, comments, docs, memories; clean up anything stale as you go.
