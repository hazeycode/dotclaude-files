---
name: land-lane
description: Land a finished worker lane — skeptical read, gate battery on the pinned lane tip, stage the merge as the review surface, watch for the human's verdict. The HUMAN authors the landing merge on the target branch (main by default); every exit records findings and ends with the human's retire-or-continue ruling. Use when a background lane reports complete.
---

# Land a lane (human-review flow)

The coordinator VERIFIES; the HUMAN merges. Every lane that changes anything
lands through the human's review — no exceptions, docs-only included; a no-diff
lane is a report, not a landing (step 2). The TARGET branch is main unless the
human names another at land time. Commit scope: the coordinator may commit on
LANE branches (update-merges, checkpoints); the landing merge on the TARGET is
the human's, always. Review tool: `LANE_REVIEW` in the settings `env` block
(read at session start) — unset/`vscode` runs step 8's recipe; `manual` skips
the launch for the human's own tooling.

## Checklist, in order

1. **Read the report skeptically.** Claims must cite evidence the lane produced
   (exit codes seen, files written). A number quoted without its source gets
   re-read, not trusted.
2. **Report-only short-circuit.** `git diff --quiet <target>...<lane>` — quote and
   map the exit code: **0** = findings only, nothing to review: do step 9's
   recording duties, then its retire-or-continue question (same rules). **1** =
   changes exist: continue. **≥128** = the probe itself failed (bad branch, no
   merge base): stop and investigate — a failed probe is never "continue".
3. **Update the lane branch from the target**: merge <target> INTO the lane, in its
   worktree, exit code quoted — an in-scope coordinator commit on the lane
   branch. Conflicts go to the human unresolved, never quietly fixed; after
   the human commits the resolution, re-enter here — a resolved tree is a new
   tree, so steps 4–6 rerun on it.
4. **Full gate battery on the updated lane tip, BEFORE the review — and pin
   it**: record `gated=$(git rev-parse <lane>)` with the verdict; step 7
   refuses any other tip. Explicit exit codes, never laundered through
   `tail`/`head` in a `&&` chain. Known-red gates must be red exactly as
   documented — drift is a real regression. There is NO post-commit battery:
   when the human edits during review, say so in the record; the NEXT
   battery's first suspect for new red is that record, not its own lane.
   After a stretch's LAST landing, offer a one-off battery on the target — no
   automatic backstop exists.
5. **Golden values, same tree**: every probe against documented values; check
   the build's exit code first — a failed build leaves the old binary printing
   a confident wrong answer.
6. **Visuals**: if pixels can move, re-capture the standard poses and LOOK at
   before/after yourself before presenting; rotate baselines only after your
   own eyes pass them.
7. **Stage the merge** (coordinator stages; only the human commits on the
   target). Prechecks, each exit code quoted:
   - checkout on <target> (`git branch --show-current`) and CLEAN
     (`git status --porcelain` empty) — else stop and surface; stray
     record-edits never ride into the human's merge commit;
   - freshness: `git merge-base --is-ancestor <target> <lane>` exit 0 — else
     the target moved and a clean auto-merge would stage a tree nobody gated:
     back to 3;
   - tip pin: `git rev-parse <lane>` equals `gated` — else back to 4.
   Then `git merge --no-ff --no-commit <lane>` (exit code) and record
   `staged_tree=$(git write-tree)` — step 9 diffs against it. If
   `git diff --cached --quiet` exits 0 the merge is EMPTY (the target already
   absorbed the content): abort and exit via step 2 — never park the human on
   a review of nothing. Write the commit prompt into `.git/MERGE_MSG`: subject
   `Merge <lane>: <one-line summary>`, body = what landed plus the battery
   verdict — the human's commit box prefills from it (a bare `git commit`
   opens it in the editor); they edit and author it. One landing at a time; touch nothing in the primary
   checkout while a merge is staged.
8. **Present and WATCH.** The staged merge IS the review surface; edits the
   human makes become part of the merge commit they author. Recipe per
   `LANE_REVIEW`: unset or `vscode` → the bullet below; `manual` → launch
   NOTHING — the human views the staged merge with their own tool (anything
   showing staged changes on the primary checkout; `git diff --cached` at
   minimum; TUIs they run themselves). Unknown value → say so, treat as
   manual; never guess a launch command. Everything else in this step is
   identical either way.
   - VS Code: sed `{{REPO}}` (checkout abs path) + `{{LANE}}` (branch) in the
     vendored `land-review.code-workspace.template` into a UNIQUELY-NAMED
     `land-review-<lane>.code-workspace` (an already-open workspace focuses
     without re-firing folderOpen tasks — re-present = fresh name), then
     `code -n <file>`: a workspace's own window identity opens a NEW window
     even when the folder is open elsewhere (`code -n <folder>` silently
     no-ops there). ONLY the primary checkout goes in the window — the lane
     worktree as folder or terminal cwd biases active-repo resolution and
     blanks the staged-diff view (hit live 2026-08-25). The template opens
     the staged multi-diff + Git Graph (`mhutchie.git-graph` required), one
     `${command:}` per task (an undefined return cancels the task's remaining
     resolution). Caveats: `task.allowAutomaticTasks` is APPLICATION-scoped —
     "on" in USER settings once per machine; untrusted workspaces suppress
     folderOpen silently. Delete the instantiated file at cleanup. Exit codes
     prove dispatch, not display — only the human's eyes confirm the view.
   Tell the human: branch, target, the lane's commits
   (`git log --oneline <target>..<lane>`), cumulative diffstat
   (`git diff --stat <target>...<lane>`), battery verdict with exit codes,
   report digest. Then run the vendored
   `watch-merge.sh <repo> <lane> <target>` in the background — BOUNDED (1 h default), PRINTS `ACCEPTED <sha>` / `REJECTED` /
   `TIMEOUT` the moment MERGE_HEAD resolves. ACCEPTED or REJECTED → step 9
   (the watch is a trigger, not proof). TIMEOUT → ask the human; never re-arm
   silently. "Changes requested" arrives as words, at any point.
9. **Act on the verdict. EVERY exit records** verified findings (not lane
   claims), simplification candidates, folded DRAFT entries — **and ends with
   the retire-or-continue question**: retire (kill lane, remove worktree,
   delete branch — requires `git -C <worktree> status --porcelain` EMPTY;
   anything uncommitted goes to the human, never `--force` unasked) or
   continue (branch and worktree stay; the lane takes its next brief; its
   next land re-enters at 3). Never retire unasked.
   - *Accepted*: verify the human's merge commit on the target (`git log`,
     your own eyes) before recording anything.
   - *Rejected / Changes requested* — preserve review edits BEFORE aborting:
     `git diff <staged_tree> > <worktree>/land-review-edits.patch` (non-empty
     means the human edited; it applies in the lane worktree with
     `git apply`). Then `git merge --abort` and check STATE, not just exit:
     if MERGE_HEAD persists (abort refuses on unstaged edits),
     `git reset --hard HEAD` — safe, the edits are in the patch. Rejected:
     ask and record the reason. Changes requested: the notes plus the patch
     are the lane's next brief; re-land from 3 when it reports.
10. **Decisions surfaced by the lane** go to the human as crisp options with
    evidence attached — never silently resolved, never re-litigated once
    ruled.
