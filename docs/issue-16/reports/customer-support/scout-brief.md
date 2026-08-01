# Scout brief — issue-16 (gate A+ 최종 마감)

## Skip record

Scouting skipped. Reason: this issue is a conservative remediation of
confirmed defects against an already-landed, already-designed upstream
reference (core issue-75's guarded-source form and
`gate_bash_write_targets` py parity, plus this repo's own README/message
staleness) — no open design decision remains to steer with external
exemplars; the fix shape is dictated by `survey.md`'s findings and
`docs/handbooks/gate-house-standard.md` (core, already read in full),
matching the same skip condition issue-75's own proposal recorded for
itself ("pure-bugfix condition"). Per the scout-directive's two stated
skip conditions ("pure bugfix" / "spec literally leaves no design
decision open"), both apply here: items 1-3 are reference-adopt of a
byte-identical upstream fix; items 4-6 are stale-reference corrections
with only one correct answer (remove the ghost line; rename the stale
filename to the file that actually exists).

## Gap line (what the current state already meets vs. what it misses)

Already meets: the reference-not-vendor pattern itself (issue-13
already migrated all seven gates to *source* `gate-lib.sh` by reference
rather than reimplementing its functions), the `CLAUDE_PLUGIN_ROOT_CORE`
sibling-fallback resolution convention, and the sh-side `gate-lib.sh`
canon being current (issue-75's sh-side changes are guard-form-only,
already structurally compatible with how these seven gates call it).

Misses (survey.md, full detail): the guard itself (`||` fallback) on
all seven source lines; the py-side `gate_bash_write_targets` reuse
(seven gates still hand-roll a divergent regex); the missing-core test
group (core's 7th mandatory group, present in canon's own
`run-gate-lib-tests.sh`, absent from all seven of this repo's suites);
two independently-confirmed stale-reference defects (README's deleted
`warrant-hunter.md` line; three `directive-fragment.sh` files' stale
`hooks/gate.sh` filename); and one message/checklist-rigor gap specific
to five-whys (mechanical check accepts any five question-shaped lines,
not the checklist's specific causal-chain questions or its `§2.5`
convergence rule, with no judgment-layer caveat stating this the way
three sibling plugins' fragments do).

## Sources

- `docs/handbooks/gate-house-standard.md` (core repo, read in full —
  local path `/home/jwjung/tokenmaxxxer/tokenmaxxxer-core`, confirmed
  landed at commit `52bdc15`).
- `docs/issue-75/reports/implementation.md` (core repo, read in full).
- This repo's own `docs/issue-2/reports/implementation.md` (warrant-hunter
  deletion record) and `docs/issue-13/proposals/customer-support.md`
  (prior reference-adopt precedent, same repo).

Stage count: 0 (scouting skipped per the recorded condition above; no
sweep or deepening stage ran).
