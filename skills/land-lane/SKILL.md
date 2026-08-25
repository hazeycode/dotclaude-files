---
name: land-lane
description: Merge a finished worker lane's branch and verify it honestly — explicit exit codes, re-run gates on the merged tree, inspect visual output, record rulings. Use when a background lane reports complete.
---

# Land a lane

A lane's green gates were run on ITS tree, which predates everything you merged
since it branched. Landing is the coordinator's verification pass, not a rubber
stamp.

## Checklist, in order

1. **Read the report skeptically.** Claims must cite evidence the lane actually
   produced (exit codes it saw, files it wrote). A report that quotes a number
   without its source gets the number re-read, not trusted.
2. **Merge with explicit exit codes.** Never pipe a merge or gate through
   `tail`/`head` inside `&&` — it launders the exit code. Capture `$?` on its own
   line. A conflicted merge that "looked fine" has shipped before.
3. **Re-run the full gate suite on the merged tree.** The lane's own gate quotes
   are stale by construction if anything else merged meanwhile. Known-red gates
   must be red in exactly the documented way — count the expected failures and
   grep for the not-the-known-breach marker; any drift is a real regression.
4. **Golden values**: re-run every hash/golden probe and compare against the
   documented values. Check the build's exit code before trusting any probe's
   output — a failed build leaves the previous binary in place, which prints a
   confident wrong answer.
5. **Visual output**: if the change can move pixels, re-capture the standard
   poses and LOOK at before/after yourself. Metrics under auto-exposure read
   defective frames as healthy. Send the pairs to the user; rotate baselines only
   after your own eyes pass them.
6. **Record**: update the task with what was verified (not just what the lane
   claimed), fold any DRAFT ledger/plan entries into their owning documents, and
   file the lane's simplification candidates somewhere they won't be lost.
7. **Decisions surfaced by the lane** go to the user as crisp options with the
   evidence attached — never silently resolved by you, never re-litigated once
   ruled.
