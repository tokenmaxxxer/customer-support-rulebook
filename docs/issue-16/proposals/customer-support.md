# Proposal — issue-16: 게이트 A+ 최종 마감 (2026-08-01 재감사 잔여 결함)

Phase-1 proposal only. Does not implement; phase 2 opens on Approve per
role-handoff contract v3 s19.

## 1. Precondition check

Both named preconditions are landed, confirmed by direct read
(survey.md, scout-brief.md):
- core issue-75 (`tokenmaxxxer/tokenmaxxxer-core` commit `52bdc15`,
  PR #77): `gate-lib.sh`'s guarded-source usage comment,
  `compliance-check.sh`'s unguarded-source check,
  `gate-lib.py`'s `gate_bash_write_targets`, and
  `run-gate-lib-tests.sh`'s 7th mandatory `missing-core` group.
- on-the-record issue-182 (`CLAUDE_PLUGIN_ROOT_CORE` injection in
  spawn.py) — outside this repo's write scope to re-verify; this repo's
  existing `${CLAUDE_PLUGIN_ROOT_CORE:-<sibling fallback>}` resolution
  is already the correct consumer shape regardless.

This proposal adopts core's confirmed guard/parity shape **by
reference**, never re-derives it, per `gate-house-standard.md`'s
reference-not-copy rule — the same discipline issue-13 already applied
to this repo's `gate-lib.sh` sourcing.

## 2. Scope

All seven `customer-support-*/hooks/*-gate.sh` scripts and their
`tests/customer-support-*-gate-tests.sh` suites; `README.md`; three
`directive-fragment.sh` files (`sla-tier`, `evidence-metric`,
`escalation-path`); `five-whys`'s mechanical check. Full defect
inventory: `survey.md`.

## 3. Guarded source line (all seven gates) — survey.md finding 1

Every gate's opening source line changes from:

```bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
```

to the core-confirmed guarded form (`gate-house-standard.md` §"What
`gate-lib.sh`/`gate-lib.py` provide"):

```bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" \
  || { echo "<gate-name>-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
```

with `<gate-name>` substituted per gate (`kcs`, `playbook-scenario`,
`evidence-metric`, `five-whys`, `escalation-path`, `sla-tier`,
`phase1-order`), matching the stderr-naming convention core's own seven
`core/hooks/*.sh` gates use. This closes the exact issue-75 defect
(silent no-op when core is unreachable) survey.md finding 1 confirmed
still open in all seven gates here.

## 4. Bash-path-scan parity — survey.md finding 2

Each gate's `candidate_paths()` Bash branch changes from the hand-rolled

```python
return re.findall(r'[\w./~-]+', tool_input.get("command", ""))
```

to a direct call on the now-available canon function:

```python
return gate_lib.gate_bash_write_targets(tool_input.get("command", ""))
```

This removes the char-class divergence (missing `$`) survey.md
identified and makes this repo's Bash-token-candidate set identical, by
construction, to core's own canon and to whatever the 43-rulebook
remediation batch's other repos converge on — the actual "matcher-code
parity" issue requirement 2 asks for: not just that the `hooks.json`
matcher (`".*"`, already correct in all seven) reaches the code path,
but that the reached code path computes the same candidate set core's
own tests exercise.

## 5. `missing-core` mandatory test case — survey.md finding 3

Add a 7th case group to each of the seven
`tests/customer-support-*-gate-tests.sh` suites, mirroring core's own
`run-gate-lib-tests.sh` group 7: invoke the gate with
`CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path and no valid
relative fallback (temporarily rename/hide the sibling `../../core` in
the test's own sandboxed working copy, the same isolation
`tests/lib/harness.sh` already sets up for its real-core-checkout
resolution), asserting **deny** (exit 2) — the corrected behavior once
§3's guard lands, replacing the current silent-allow behavior survey.md
confirmed. This is the delivery-time proof that §3's fix actually
fires, not just that the source line's text changed.

Delivery gate (mirrors issue-13's own §5 convention): full seven-suite
green via the existing `bash tests/customer-support-*-gate-tests.sh`
invocation, plus `core/hooks/tests/compliance-check.sh <this-repo>`
clean — its output is the delivery evidence for requirement 3
("missing-core 케이스 포함 전 스위트 배송 상태 green + compliance-check
통과 record 기록"), recorded in the phase-2 record file
(`docs/issue-16/reports/customer-support.md`).

## 6. README sync — survey.md finding 4

Remove the ghost `customer-support/agents/warrant-hunter.md` line from
`README.md`'s Layout section (the file was deleted in issue-2; the
directory `customer-support/agents/` does not exist). No replacement
line is needed — issue-2's own record already established that this
role relies on core's canonical `warrant` plugin instead of a
role-local copy; README should simply stop naming a file that is not
there.

## 7. Stale-filename fix in three directive-fragment.sh files — survey.md finding 6

`customer-support-sla-tier/hooks/directive-fragment.sh`,
`customer-support-evidence-metric/hooks/directive-fragment.sh`, and
`customer-support-escalation-path/hooks/directive-fragment.sh` each
reference `hooks/gate.sh`, a filename that does not exist in any of the
three plugins (the real files are `sla-tier-gate.sh`,
`evidence-metric-gate.sh`, `escalation-path-gate.sh`). Each occurrence
is corrected to name its own actual gate script
(`hooks/sla-tier-gate.sh`, `hooks/evidence-metric-gate.sh`,
`hooks/escalation-path-gate.sh` respectively), text-only, no behavior
change to the SLA-tier ITIL-matrix, escalation-path owner/timeout, or
evidence-metric causal-sentence norms those same fragments already
document (`scout-brief.md`'s gap line: those norms are already met and
untouched by this proposal).

## 8. Five-whys message/checklist rigor gap — survey.md finding 5

Two independent, additive corrections, matching the pattern the three
`§7` plugins already use (an explicit "the gate can only check X; this
directive/checklist covers Y" caveat, per `scout-brief.md`'s gap line
on this same five-whys message/checklist-rigor pattern):

1. **`five-whys-gate.sh` deny message** (per `scout-brief.md`'s gap
   line on the five-whys message/checklist-rigor gap): state plainly,
   in the deny reason string, that the mechanical check verifies
   presence-and-count of question-shaped lines only ("5-whys" label +
   >=5 lines ending `?`) and does **not** verify that the five
   questions match `checklists/5-whys-recurring.md`'s specific
   causal-chain questions, nor the checklist's `§2.5` convergence rule —
   those remain the judgment layer's responsibility, exactly as
   `evidence-metric`'s and `escalation-path`'s fragments already state
   for their own facets.
2. **`directive-fragment.sh`** (same `scout-brief.md` gap-line basis
   for this five-whys correction): add the same "gate can only check
   shape; this is the judgment layer for the rest" framing sentence
   the three §7 plugins already carry, naming `five-whys-gate.sh`
   correctly (no stale-filename risk here — confirmed absent in
   survey.md finding 6's scan) and pointing at `§2.5`'s convergence rule
   by name as the specific judgment-only requirement.

This is a documentation/message-text change only — no change to what
`five-whys-gate.sh` mechanically enforces (out of scope, §9), since
widening the mechanical check to actually parse causal-chain
convergence is a semantic-check design task on the same order as
issue-13's §4 section/adjacency work, not a one-line remediation, and
is not what this issue asks for.

## 9. Out of scope for this proposal

- Any change to what each gate's mechanical check *requires* in
  content-norm terms — SLA-tier's ITIL-matrix traceability,
  escalation-path's named-owner/timeout requirement, evidence-metric's
  causal-sentence requirement, KCS article shape, or phase1-order's
  playbook-scenario/artifact-order requirement (all per
  `scout-brief.md`'s gap line: this repo's existing judgment-level
  directives for those norms, unaffected by this proposal, which only
  fixes the source-guard/parity/test/doc defects survey.md found) — is
  out of scope here.
- Building a mechanical parser for five-whys' causal-chain-convergence
  (`§2.5`) rule (per `scout-brief.md`'s gap line, five-whys' own
  judgment-only rule, unchanged by this proposal) — §8 only adds the
  documentation caveat that this rule is judgment-only, matching the
  existing pattern for three sibling plugins; a future issue may
  propose the parser itself.
- Migrating any other rulebook repo — this proposal covers only
  `customer-support-rulebook`.
- Re-verifying on-the-record issue-182's `spawn.py` injection —
  outside this repo's write scope.

## 10. Phase-2 acceptance criteria (for the Approve gate, not decided here)

- All seven gates source `gate-lib.sh` with the `||` guard, each
  stderr message naming its own gate file.
- All seven gates' Bash-path candidate scan calls
  `gate_lib.gate_bash_write_targets` (no hand-rolled regex remaining).
- All seven test suites carry a passing `missing-core` (group 7) case;
  full seven-suite run green.
- `core/hooks/tests/compliance-check.sh` clean against this repo's
  `hooks/`, recorded as delivery evidence in
  `docs/issue-16/reports/customer-support.md`.
- `README.md` contains no `warrant-hunter.md` reference.
- The three `directive-fragment.sh` files name their own real gate
  script, not `hooks/gate.sh`.
- `five-whys-gate.sh`'s deny message and `directive-fragment.sh` both
  state the mechanical-check/judgment-layer split explicitly.
- No pre-round-3/pre-issue-10 role name or ghost file remains in
  `README.md`, any `plugin.json`, or `marketplace.json` (survey.md's
  manifest audit found none currently — this is a delivery-time
  regression check, not new work).
