# customer-support-rulebook

Rulebook for the `customer-support` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion and
generated as skeleton scaffolding by issue-170.

- **decides**: 문의를 어떤 우선순위/SLA로 처리할지
- **use_when**: CS 플로우/SLA 설계가 걸릴 때
- **produces**: support playbook, SLA table, escalation path
- **write_scope**: []
- **hand-off**: 반복 문의가 제품 결함이면 → product-discovery

## Install

```
claude plugin marketplace add tokenmaxxxer/customer-support-rulebook
claude plugin install customer-support
```

## Layout

- `customer-support/.claude-plugin/plugin.json` — plugin manifest
- `customer-support/hooks/hooks.json` — SessionStart wiring
- `customer-support/hooks/directive.sh` — SessionStart role directive
- `customer-support/hooks/lib/semantic.py` — shared section/adjacency
  semantic-check helper used by the plugin gates below (issue-13; not
  part of core's `gate-lib.sh`/`.py`, this rulebook's own local design)
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

### Methodology-enforcement gate plugins (issue-10, hardened issue-13)

Each of the following is its own installable plugin, each with a
`PreToolUse` gate on `Write`/`Edit`/`MultiEdit`/`Bash` writes to
`customer-support/handbook.md` or `docs/issue-<n>/reports/customer-support.md`
(phase1-order instead targets `docs/issue-<n>/proposals/customer-support.md`).
Every gate sources core's `core/hooks/lib/gate-lib.sh`/`.py` (issue-72
gate-house standard) by reference — resolved via
`${CLAUDE_PLUGIN_ROOT_CORE:-<sibling ../../core>}`, never vendored — for
its trap/kill-switch/path-normalize/reconstruct/deny machinery. Kill
switch: any recognized on-spelling (`1`/`true`/`yes`/`on`,
case-insensitive) disables the gate; every other value, including an
unrecognized typo, keeps it active (fail-closed).

| Plugin | Gate script | Kill-switch env var |
|---|---|---|
| `customer-support-kcs` | `hooks/kcs-gate.sh` | `CUSTOMER_SUPPORT_KCS_GATE_OFF` |
| `customer-support-playbook-scenario` | `hooks/playbook-scenario-gate.sh` | `CUSTOMER_SUPPORT_PLAYBOOK_SCENARIO_GATE_OFF` |
| `customer-support-evidence-metric` | `hooks/evidence-metric-gate.sh` | `CUSTOMER_SUPPORT_EVIDENCE_METRIC_GATE_OFF` |
| `customer-support-five-whys` | `hooks/five-whys-gate.sh` | `CUSTOMER_SUPPORT_FIVE_WHYS_GATE_OFF` |
| `customer-support-escalation-path` | `hooks/escalation-path-gate.sh` | `CUSTOMER_SUPPORT_ESCALATION_PATH_GATE_OFF` |
| `customer-support-sla-tier` | `hooks/sla-tier-gate.sh` | `CUSTOMER_SUPPORT_SLA_TIER_GATE_OFF` |
| `customer-support-phase1-order` | `hooks/phase1-order-gate.sh` | `CUSTOMER_SUPPORT_PHASE1_ORDER_GATE_OFF` |

Tests: `tests/customer-support-<name>-gate-tests.sh`, sharing
`tests/lib/harness.sh`. Run all seven with
`bash tests/customer-support-*-gate-tests.sh` (requires
`CLAUDE_PLUGIN_ROOT_CORE` to resolve to a `tokenmaxxxer-core` checkout —
see `tests/lib/harness.sh`'s resolution fallback). Delivery evidence for
issue-13: all seven suites green plus
`core/hooks/tests/compliance-check.sh <this-repo>` reporting `ok` for
all seven gate scripts.

This is scaffolding, not a finished rulebook: fill in doctrine detail,
handoff enforcement, and any role-specific progress gate before treating
it as load-bearing.
