# Record: methodology enforcement machinery delivered as a plugin set (issue-10)

Subject: issue-10. Phase 2 delivery, on the same branch/PR as the
approved proposal (`docs/issue-10/proposals/customer-support.md`).
Opened by the `APPROVE issue-10/customer-support` issue comment
(single-account mode, `JiwonJung94` on `docs/specs/approvers.md`).

loop_state: landed

## Why

Issue-10 asked that the domain methodology adopted in issue-1
(`docs/issue-1/proposals/customer-support.md` §2/§3) stop living only
as a directive summary line and documentation, and instead be
mechanically enforced the way `implementation-rulebook` enforces its
own norms. The approver's PR #11 review corrected the shape from one
monolithic gate to an independent plugin set (one methodology = one
plugin), then a domain-review WEAK verdict added explicit ITIL naming,
KCS adoption, and a 5-whys scope bound. This record is the phase-2
build against that approved, twice-revised proposal — upstream basis:
`docs/issue-10/proposals/customer-support.md`, itself based on
`docs/issue-10/reports/customer-support/{survey.md,scout-brief.md}`
and `docs/issue-1/proposals/customer-support.md`.

## What was done

Seven independently loadable plugins, one per adopted methodology from
`docs/issue-1/proposals/customer-support.md` §2/§3, each self-contained
(own `.claude-plugin/plugin.json`, `hooks/hooks.json`,
`hooks/directive-fragment.sh`, `hooks/gate.sh`, root-level
`tests/<name>-gate-tests.sh`), matching the proposal's §0 plugin list
exactly:

| Plugin | Methodology | Norm |
|---|---|---|
| `customer-support-sla-tier` | ITIL Impact×Urgency SLA-tier table | phase-2 |
| `customer-support-escalation-path` | trigger/owner/timeout escalation tiers | phase-2 |
| `customer-support-playbook-scenario` | trigger/decision-criteria/script/escalation-condition | phase-2 |
| `customer-support-evidence-metric` | CSAT/FCR/SLA-adherence citation | phase-2 |
| `customer-support-five-whys` | repeat-pattern 5-whys check + `checklists/5-whys-recurring.md` | phase-2 |
| `customer-support-phase1-order` | 3-artifact order + uncited-claim prohibition | phase-1 |
| `customer-support-kcs` | KCS Content Standard article shape | phase-2 |

Each gate (PreToolUse, `.*` matcher) reads the tool-call JSON on stdin,
fails closed on unparseable payload (`exit 2`), passes through
non-`Write`/`Edit`/`MultiEdit` calls and paths outside its own target
regex, and on a real match denies via
`hookSpecificOutput.permissionDecision: "deny"` naming every missing
element by facet token, per the proposal's §2 deny-message shape. Each
carries its own kill switch
(`CUSTOMER_SUPPORT_<PLUGIN>_GATE_OFF=1`). No plugin reads another's
output or state — the phase-2 norm is the union of six gates firing
independently on the same write surfaces
(`^customer-support/handbook\.md$`,
`^docs/issue-[0-9]+/reports/customer-support\.md$`), exactly as
proposal §2 specifies. `customer-support-phase1-order` alone targets
`^docs/issue-[0-9]+/proposals/customer-support\.md$` and additionally
checks that `survey.md`/`scout-brief.md` already exist on disk before
allowing a proposal write (order check), on top of its citation check.

`.claude-plugin/marketplace.json` registers all seven as additive
entries; the existing `customer-support` entry and its
`hooks/directive.sh` / `hooks/hooks.json` are untouched, per proposal
§0/"Phase-2 write set".

### Tests

Seven root-level files, `tests/customer-support-<plugin>-gate-tests.sh`,
each independently runnable (`bash tests/<file>`), no shared harness.
Every file covers: one full-pass case, one deny case per required
element (isolated by removing exactly that element from the pass
fixture), a kill-switch-bypass case, a malformed-JSON fail-closed case
(`exit 2`), and a non-`Write`/`Edit`/`MultiEdit` passthrough case. All
seven suites pass: 16 + 7 + 9 + 8 + 7 + 7 + 10 = 64 cases, 0 failures
(verified this session by running each file directly).

`customer-support-five-whys`'s pass-case fixture carries a comment
noting the §2.5 scope bound (multi-cause 5-whys blocks route to
product-discovery on that basis alone) as a directive-level judgment
the gate script cannot check — per proposal §4.

### Deviations from the proposal, and why

- **No `core/` dependency in the new gates.** The existing
  `customer-support` plugin's `hooks/directive.sh` sources a `core/`
  lib via a relative path (`../../core/hooks/lib/role-directive.sh`),
  but no `core/` checkout exists in this repo (canon lives in a
  separate marketplace repo, referenced not copied per
  `docs/handbooks/canon-scripts.md`). The seven new gate/directive
  scripts are therefore fully self-contained bash (`jq` for JSON,
  `grep -E`/`grep -qi` for element checks) rather than sourcing a core
  lib that isn't present to reference. This does not copy any canon
  script — the checking logic is new, role-specific content, matching
  proposal §0's explicit "none of these seven files is `core/` canon"
  framing.
- **Facet-token granularity for `five-whys`**: the proposal's §2.5 gate
  spec describes two sub-conditions (5-whys label present; ≥5
  question-lines present) but names a single collective
  `missing.append("5-whys-check")` token — implemented as one shared
  facet token for both sub-failures, matching the proposal's literal
  wording over a finer split.
- **Section-scoping simplification**: several gates (`escalation-path`,
  `playbook-scenario`, `kcs`, `phase1-order`'s citation check) check
  "same section" requirements via whole-content substring matching
  rather than parsing markdown section boundaries in bash. This is the
  same presence-not-correctness trade-off the proposal's open question
  2 already flags for `five-whys`, extended consistently to the other
  gates that share the same "detect a marker, then require elements
  nearby" shape — precise section isolation is left to each plugin's
  directive-fragment judgment layer, not the gate.

### Not built (per proposal §3, reasoned)

No `warrant`-style cross-session state-rebuild script, and no `agents/`
addition for `five-whys` (content-authoring checklist only, not an
autonomous subagent task) — both explicitly out of scope per proposal
§3/§2.5.

## Open findings

None outstanding — all seven plugins built, wired into
`marketplace.json`, and their test suites pass (64/64 cases). The
proposal's four open questions to the approver (deliverable file path,
5-whys detection heuristic being shape-not-semantic, seven-plugin
registration overhead, KCS/playbook-scenario overlap) were flagged for
awareness in the approved proposal itself and are not blockers; none
surfaced a defect during this build.
