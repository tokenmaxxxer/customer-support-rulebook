# Record: 게이트 A+ 최종 마감 — 재감사 잔여 결함 보수 (issue-16)

Subject: issue-16. Phase-2 delivery, on the same branch/PR as the
approved proposal (`docs/issue-16/proposals/customer-support.md`).
Opened by the `APPROVE issue-16/customer-support` issue comment
(single-account mode, `JiwonJung94` on `docs/specs/approvers.md`).

loop_state: landed

Issue: seven `customer-support-*-gate.sh` scripts silently no-op'd when
`CLAUDE_PLUGIN_ROOT_CORE` was unreachable, hand-rolled a Bash-path scan
diverging from core's canon char class, carried no delivery-time proof
the missing-core guard fires, and README/directive-fragment text held
a ghost `warrant-hunter.md` line and three stale `hooks/gate.sh`
references left over from issue-13's `gate.sh` to `<name>-gate.sh`
rename.
Environment: this repo's seven `customer-support-*` gate plugins
(`customer-support-kcs`, the trigger/decision-criteria/script/
escalation-condition plugin, `customer-support-evidence-metric`,
`customer-support-five-whys`, `customer-support-escalation-path`,
`customer-support-sla-tier`, `customer-support-phase1-order`),
`README.md`.
Resolution: guarded source line + `gate_bash_write_targets` parity +
`missing-core` test case added to all seven, `README.md`/three
`directive-fragment.sh` files/five-whys deny message synced — full
detail below.
Cause: core issue-75's guard/parity fix landed after this repo's
issue-13 gate migration and was never back-applied here; the
issue-13 `gate.sh` to `<name>-gate.sh` rename updated `hooks.json` and
test `GATE=` paths but missed the three `directive-fragment.sh` files'
prose references and README's already-stale `warrant-hunter.md` line
(dangling since issue-2).
Metadata: state=delivered, maturity=validated

## Why

The 2026-08-01 재감사 found this repo's gate scripts still open against
core issue-75's confirmed fix (silent-allow when
`CLAUDE_PLUGIN_ROOT_CORE` is unreachable), a hand-rolled Bash-path scan
diverging from core's canon `gate_bash_write_targets` char class, no
delivery-time proof the missing-core guard actually fires, and stale
README/directive-fragment text (a ghost `warrant-hunter.md` line, three
plugins naming a `hooks/gate.sh` file that does not exist post-issue-13
rename). Left unfixed, these gaps mean SLA-tier/escalation-path/
evidence-metric enforcement can silently no-op exactly when core is
unreachable — the same production-inoperative failure mode issue-13
already closed for the path-anchor/fail-closed-trap class, now
reopened for the source-guard class. Fixing it keeps the SLA-tier and
escalation-path gates actually load-bearing against SLA-adherence in
production, not just in the common case where core happens to resolve.

## What was done (per approved proposal §3-§8)

- **Guarded source line (all seven gates, §3):** every
  `customer-support-*/hooks/*-gate.sh` now sources `gate-lib.sh` with an
  or-guard that prints `"<gate-name>-gate.sh: cannot source gate-lib.sh"`
  to stderr and exits 2 on failure to source, matching core's own seven
  `core/hooks/*.sh` gates' stderr-naming convention — closes the exact issue-75 defect (silent no-op when core
  is unreachable) survey.md confirmed still open in all seven.
- **Bash-path-scan parity (all seven gates, §4):** every gate's
  `candidate_paths()` Bash branch now calls
  `gate_lib.gate_bash_write_targets(tool_input.get("command", ""))`
  instead of the hand-rolled `re.findall(r'[\w./~-]+', ...)`, removing
  the missing-`$` char-class divergence survey.md identified. `hooks.json`
  matcher parity was already correct in all seven (`".*"` on
  `PreToolUse`, reaching the code path that now computes core's own
  candidate set) — confirmed by direct read, no change needed.
- **`missing-core` mandatory test case (all seven suites, §5):** each
  `tests/customer-support-*-gate-tests.sh` gained a 7th case group
  (`missing-core-denies`), invoking the gate with `CLAUDE_PLUGIN_ROOT_CORE`
  pointed at a nonexistent path (no valid relative fallback) and
  asserting exit 2 — the delivery-time proof §3's fix actually fires,
  mirroring core's own `run-gate-lib-tests.sh` group 7.
- **README sync (§6):** removed the ghost
  `customer-support/agents/warrant-hunter.md` Layout line (file deleted
  in issue-2; role already relies on core's canonical `warrant` plugin).
- **Stale-filename fix (§7):** the SLA-tier/evidence-metric/
  escalation-path plugins' `directive-fragment.sh` files now name their
  own real gate script (`sla-tier-gate.sh`/`evidence-metric-gate.sh`/
  `escalation-path-gate.sh`) instead of the nonexistent `hooks/gate.sh`,
  text-only, no content-norm change.
- **Five-whys message/checklist rigor (§8):** the five-whys gate's
  deny message and its `directive-fragment.sh` both now state plainly
  that the mechanical check verifies presence-and-count of
  question-shaped lines only, not the checklist's specific causal-chain
  questions nor its §2.5 convergence rule — matching the pattern the
  evidence-metric/escalation-path/sla-tier fragments already use.
- **Manifest/README name audit (§9, delivery-time regression check):**
  `README.md`, `.claude-plugin/marketplace.json`, and every
  `customer-support-*/.claude-plugin/plugin.json` scanned for
  pre-round-3/pre-issue-10 role names or ghost files — none found beyond
  the warrant-hunter line already fixed above.

## Delivery evidence

Full seven-suite run, this session, `bash tests/customer-support-<plugin>-gate-tests.sh`
for each of the seven files (including the new `missing-core-denies`
case): kcs 19, escalation-path 18, evidence-metric 15, five-whys 16,
phase1-order 17, the trigger/decision-criteria/script/
escalation-condition suite 19, sla-tier 21 — **125/125, 0 failures**.

`core/hooks/tests/compliance-check.sh` run against each of the seven
`customer-support-*/hooks/` directories (local `tokenmaxxxer-core`
checkout, core issue-75 commit): `ok` for all seven gate scripts — no
hand-rolled kill-switch case statement, no unguarded source line, no
un-migrated `.replace()` reconstruction detected.

## This delivery's own priority classification

Per the sla-tier plugin's ITIL Impact x Urgency matrix convention, this
defect class classifies as:

| Priority | Impact | Urgency | First response | Resolution | Escalation trigger |
|---|---|---|---|---|---|
| P1 | High (every write to a governed target, across all seven plugins, silently bypasses enforcement whenever core is unreachable) | High (blocks the 43-rulebook remediation batch's shared guard/parity baseline) | same session | same session | unresolved past this session's delivery window escalates to a re-audit issue |

## Evidence-metric mechanism

This delivery's SLA-adherence relevance: the guarded source line turns
"core unreachable" from a silent pass-through into a hard deny (exit
2), so an SLA-tier or escalation-path write that would otherwise slip
past the enforcement layer whenever `CLAUDE_PLUGIN_ROOT_CORE` fails to
resolve now gets refused instead — closing the exact gap that would let
an SLA-tier table ship without its required Impact x Urgency-traceable
columns, or an escalation tier ship without a named owner/timeout, in
the one failure mode (missing/unreachable core) the mechanical gate
previously could not catch at all. That is what keeps the SLA-tier and
escalation-path plugins' own SLA-adherence enforcement (issue-10)
operative in production under a core-unreachable condition, not just in
the common case.

## Deviations from the proposal, and why

None. All eight proposal sections (§3-§9 scope, §10 acceptance
criteria) implemented as specified; no additional defect surfaced
during delivery that the proposal did not already cover.

## Open findings

None outstanding. All seven gates carry the guarded source line and
`gate_bash_write_targets` parity, all seven test suites carry a passing
`missing-core` case and run green (125/125), `compliance-check.sh`
clean against all seven, README/manifests carry no ghost
role-name/file references, and the five-whys mechanical-check/
judgment-layer split is stated in both the gate's deny message and its
directive fragment.
