# Scout brief — issue-13

Mode: batched-sequential (single session, no parallel dispatch available for
a two-target repo read — `tokenmaxxxer-core` is the sole authoritative
exemplar named by the issue's precondition; a market sweep for third-party
"gate hardening" prior art would not outrank the canon the issue explicitly
mandates adopting). Stages: 2 (clone+read `gate-lib.sh`/`.py`, then read
`gate-house-standard.md` + `compliance-check.sh`). Judge point: would a
third stage change any build decision? No — the issue is prescriptive
("core의 게이트 하우스 표준... 참조 채택, 자체 재구현 금지"), so the exemplar
*is* the spec, not one option among several.

## Exemplar: `tokenmaxxxer/tokenmaxxxer-core` (issue-72, landed 2026-08-01)

Must-bes this rulebook's gates must satisfy to be judged compliant by the
exemplar's own `compliance-check.sh`:
- Kill switch read via `gate_kill_switch_active`, not a hand-rolled case
  statement (`compliance-check.sh:38-40`).
- `Edit`/`MultiEdit` content reconstructed via `gate_reconstruct_write`, not
  a local `.replace(old, new[, 1])` call (`compliance-check.sh:46-48`).
- `gate_trap_fail_closed` as the first statement, before `set -uo pipefail`
  (`gate-lib.sh:34-35` usage comment).
- Malformed-JSON deny via `gate_parse_json_or_deny`, path normalize via
  `gate_normalize_path`, both Python-side (`gate-house-standard.md:25-29`).
- Deny via `gate_deny` (stderr + exit 2), not stdout JSON + exit 0
  (`gate-lib.sh:70-75`, `:18`).

Performance axes the exemplar competes on:
1. **Reference, not vendor** — `gate-lib.sh`/`.py` are sourced/imported at
   run time, never copied; `stub-check.sh`'s `canon-manifest.txt` actively
   catches a vendored copy. This rulebook must resolve
   `${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh` the same way.
2. **Test-harness parity, not just library reuse** — landing gate-lib alone
   without adapting the six mandatory case groups
   (`run-gate-lib-tests.sh`: replace_all-true multi-occurrence, mixed
   MultiEdit replace_all, malformed JSON, unrecognized kill-switch value,
   absolute+`./`-prefixed path, Bash-tool write) leaves the migration
   half-done per the exemplar's own migration checklist step 3.
3. **Self-verifying via `compliance-check.sh`** — the exemplar ships its own
   detector; the migration checklist's step 5 evidence is
   `compliance-check.sh`'s clean output, not a manual claim.

Adopt: all five `gate_*` functions verbatim via source/import (never
reimplement); the migration-checklist order (compliance-check → migrate →
retest → re-check → cite); `compliance-check.sh` output as delivery
evidence.

Skip: `gate-lib.sh` does not cover facet-level semantic checks (substring
vs. section/adjacency) — that defect class (issue-13 item 2, "because"
satisfying "cause") is out of `gate-lib`'s scope (it handles structural
trap/kill-switch/path/reconstruct concerns, not per-rulebook content
semantics per `gate-house-standard.md`'s "What gate-lib.sh/.py provide"
list). This rulebook's gates must design their own section/adjacency
checker; core provides no ready-made primitive for it, so it is proposed
fresh (see proposal.md).

Gap line: current-state gates already match the exemplar's kill-switch
direction (default-active-on-unrecognized-value) — no regression risk
there. Every other must-be (trap, reconstruct, JSON-deny, path-normalize,
stderr-deny) is currently absent per survey.md items 1-5. The
substring-vs-structure semantic gap (survey.md item 3) is unique to this
rulebook's content and not addressed by the core exemplar at all.

Sources:
- https://github.com/tokenmaxxxer/tokenmaxxxer-core (core/hooks/lib/gate-lib.sh, core/hooks/lib/gate-lib.py, core/hooks/tests/run-gate-lib-tests.sh, core/hooks/tests/compliance-check.sh, docs/handbooks/gate-house-standard.md — all read directly, commit landed 2026-08-01)
