# CLAUDE.md — starter template

Copy into a new project's root and fill the brackets. **Project-specific facts
only** — the portable rules (verification, git, lanes, context economy) live in
`~/.claude/CLAUDE.md` and load alongside this file; repeating them here costs a
copy per lane. Keep every rule bought by real failure; delete anything
speculative; compress in the same edit that grows it.

## Gates

[The exact commands that must pass before any change is reported complete, run
from where. Name any gates red on purpose and EXACTLY how — count and marker —
so drift is detectable. State the clean run's stderr expectation (e.g. zero
bytes). Name any gate whose green is misleading — e.g. a build that passes
without linking the real binary — and the extra command that closes the gap.]

## Golden values

[Hashes, checksums, frozen numbers — per configuration if several. The exact
command that reprints each, and the current value. Moving one needs the owner's
explicit go-ahead and a ledger entry (see the ledger file: [path]). No moving
quantity lives in this file — read it from the artifact you built.]

## Invariants

[Purity laws and structural rules, one line each with the reason clause.
Examples worth stealing: "X is a pure function of (inputs); eviction equals
regeneration." "Module Y claims std-only imports — discipline, not a check."]

## Measurement — repo specifics

[Only what is particular here: named regimes that must not be averaged across,
instruments that lie in known ways (and the tool that doesn't), exclusive
resources and their lock command, the capture/run forms with required flags and
the line a settled run must print.]

## Running the app

[The canonical invocations: standard resolution, required pins/flags, what a
valid run prints, what invalidates one.]

## Worktree notes

[Setup a fresh worktree needs (link scripts, large fetches avoided), and any
sandbox quirks measured here.]
