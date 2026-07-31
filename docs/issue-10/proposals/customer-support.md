# Proposal: enforce the adopted methodology as an independent plugin set (issue-10)

Subject: issue-10. Phase 1 only — nothing under `customer-support/` or any
new plugin directory is edited in this PR; everything below is specified
in full but not committed until an Approve opens phase 2. Basis:
`docs/issue-10/reports/customer-support/survey.md` (current-state) and
`docs/issue-10/reports/customer-support/scout-brief.md` (internal
precedent). Norm source: `docs/issue-1/proposals/customer-support.md`
(the adopted methodology this issue enforces) — no new external
methodology claim is made; every requirement below cites back to that
document's §2/§3.

**Revision note**: this replaces the prior draft (single directive
deepening + one monolithic `methodology-gate.sh` inside the
`customer-support` plugin), per the approver's structural correction on
PR #11 — restructured below as a **plugin set**: one independently
loadable plugin per methodology, phase-1 and phase-2 norms each stated
as which plugins compose to form them, not as a bundle of edits to the
existing single plugin.

**Second revision note** (domain review, PR #11, WEAK verdict): this
revision (a) names **ITIL** explicitly as the Impact×Urgency matrix's
source standard in this document itself, not only by reference to
`docs/issue-1/proposals/customer-support.md` (§2.1, §3); (b) adopts
**KCS (Knowledge-Centered Service)** — the Consortium for Service
Innovation's canonical methodology for support-knowledge production —
as a seventh plugin, `customer-support-kcs`, governing the handbook
article/scenario shape (§2.6); (c) reconsiders 5-whys against wider
ITIL problem-management practice and states its scope bound explicitly
rather than treating it as an uncontested default (§2.5, §3). Basis:
`docs/issue-10/reports/customer-support/scout-brief.md`'s re-scout
addendum (new section, added for this revision, sources cited there).

## 0. Plugin list (mandatory)

| # | Plugin (dir) | Methodology owned | Components | Composes into |
|---|---|---|---|---|
| 1 | `customer-support-sla-tier` | Impact×Urgency SLA-tier table (§2 SLA table) | `hooks/directive-fragment.sh` (SessionStart), `hooks/gate.sh` (PreToolUse), `hooks/hooks.json`, `.claude-plugin/plugin.json` | phase-2 norm |
| 2 | `customer-support-escalation-path` | trigger/owner/timeout escalation tiers (§2 escalation path) | same shape as #1 | phase-2 norm |
| 3 | `customer-support-playbook-scenario` | trigger/decision-criteria/script/escalation-condition per scenario (§2 playbook) | same shape as #1 | phase-2 norm |
| 4 | `customer-support-evidence-metric` | CSAT/FCR/SLA-adherence citation requirement (§2 evidence metric) | same shape as #1 | phase-2 norm |
| 5 | `customer-support-five-whys` | repeat-pattern 5-whys check before hand-off decision (§2 5-whys) | `hooks/directive-fragment.sh`, `hooks/gate.sh`, `hooks/hooks.json`, `plugin.json`, **plus** `checklists/5-whys-recurring.md` (only plugin with a non-hook artifact — the procedure is repeated, per issue's "필요 시" clause) | phase-2 norm |
| 6 | `customer-support-phase1-order` | 3-artifact phase-1 order + uncited-claim prohibition (§1: survey → scout-brief → proposal, every adopted element traced to a scout-brief source) | `hooks/directive-fragment.sh`, `hooks/gate.sh`, `hooks/hooks.json`, `plugin.json` | phase-1 norm |
| 7 | `customer-support-kcs` | KCS (Knowledge-Centered Service) Content Standard article shape — Issue/Environment/Resolution/Cause/Metadata (§2.6) | same shape as #1 | phase-2 norm |
| — | `customer-support` (existing) | role identity, hand-off, write-scope (unchanged) | `hooks/directive.sh` (4-field summary, unchanged), `hooks/hooks.json` (unchanged entries) | both norms — the role plugin stays the "who/where"; the 7 methodology plugins above are the "what must be true," stacked on top the same way `core`+role+session skills already stack for this role today |

Each of #1–#7 is a **self-contained plugin**: own `.claude-plugin/plugin.json`
manifest, own `hooks.json`, own gate script, own directive fragment, own
root-`tests/` file — freelunch-worker-level completeness per plugin, not
a shared file edited seven times. None depends on another's internals;
composition happens only because all seven are registered for the same
role/session and target overlapping write surfaces (§2 below), the exact
mechanism `core`/`freelunch`/`scout` already compose by today. This
mirrors `pricing-rulebook`'s single `methodology-gate.sh` in shape
(fail-closed, kill-switch, `has_any`-style element check) but never
copies it — see `docs/handbooks/canon-scripts.md`: none of these seven
files is `core/` canon, so each is genuinely new, role-specific content.

New top-level `marketplace.json` entries (phase 2, additive — the
existing `customer-support` entry is untouched):

```json
{ "name": "customer-support-sla-tier", "source": "./customer-support-sla-tier", "description": "SLA-tier table gate (issue-10)." },
{ "name": "customer-support-escalation-path", "source": "./customer-support-escalation-path", "description": "Escalation-path field gate (issue-10)." },
{ "name": "customer-support-playbook-scenario", "source": "./customer-support-playbook-scenario", "description": "Playbook-scenario element gate (issue-10)." },
{ "name": "customer-support-evidence-metric", "source": "./customer-support-evidence-metric", "description": "Evidence-metric citation gate (issue-10)." },
{ "name": "customer-support-five-whys", "source": "./customer-support-five-whys", "description": "5-whys recurring-pattern gate + checklist (issue-10)." },
{ "name": "customer-support-phase1-order", "source": "./customer-support-phase1-order", "description": "Phase-1 3-artifact order + citation gate (issue-10)." },
{ "name": "customer-support-kcs", "source": "./customer-support-kcs", "description": "KCS Content Standard article-shape gate (issue-10)." }
```

## 1. Phase-1 norm = plugin #6 alone

`docs/issue-1/proposals/customer-support.md` §1's norm (produce exactly
3 artifacts in order — survey → scout-brief → proposal; no §2
structural claim without a scout-brief citation) is owned entirely by
`customer-support-phase1-order`. It is deliberately **not** split
further: the two halves (artifact order, citation requirement) are the
same write surface (`docs/issue-<n>/proposals/customer-support.md`) and
the same failure mode (a proposal asserting structure with no upstream
check), so splitting them into two plugins would be file-churn with no
independent-methodology justification — the "독립 플러그인" bar is one
methodology per plugin, not one check per plugin.

**Gate** (`hooks/gate.sh`, PreToolUse on
`^docs/issue-[0-9]+/proposals/customer-support\.md$`):
- Order check: refuses the write unless
  `docs/issue-<n>/reports/customer-support/survey.md` and
  `.../scout-brief.md` already exist on disk under the same `issue-<n>`
  path (`missing.append("artifact-order:survey")` /
  `"artifact-order:scout-brief"`).
- Citation check: for each §2-shaped structural keyword found in the
  new content (sla, escalation, playbook, evidence metric, 5-whys —
  same keyword list as the phase-2 plugins below), require at least one
  line in the same section citing `scout-brief.md` or a source URL
  (`missing.append("uncited-claim:<facet>")`).
- Kill switch: `CUSTOMER_SUPPORT_PHASE1_ORDER_GATE_OFF=1`.
- Fails closed on unparseable payload (`exit 2`), matching precedent.

**Directive fragment** (`hooks/directive-fragment.sh`, SessionStart,
heredoc-appended alongside the existing `directive.sh` output — same
stacking mechanism plugin #6 itself models): states the 3-step order and
the "no uncited structural claim" prohibition as an executable
judgment, one level above what the gate can check syntactically (e.g.
a citation line pointing at a scout-brief section that doesn't actually
back the claim passes the gate's regex but fails the directive's
judgment — the gate states the floor, the directive states the
judgment, same split as the prior draft's §1/§2 relationship, now scoped
to one plugin instead of bolted onto the role plugin).

## 2. Phase-2 norm = composition of plugins #1–#5 and #7

`docs/issue-1/proposals/customer-support.md` §2's five required
elements (SLA table, escalation path, playbook scenario, evidence
metric, 5-whys), plus the KCS Content Standard article shape adopted
in this revision (§2.6), are **not** one gate with six checks (the
prior draft's `methodology-gate.sh`). Each is its own plugin, each with
its own gate scoped to its own facet, all six targeting the same write
surfaces:
- `^customer-support/handbook\.md$` (current deliverable path; also
  `^docs/issue-[0-9]+/(_assets|reports)/customer-support/.*\.md$` if
  phase 2 splits the deliverable — same open question carried from the
  prior draft, unresolved here, see §5)
- `^docs/issue-[0-9]+/reports/customer-support\.md$` (the record)

The **phase-2 norm is the union of these six independent PreToolUse
gates** all firing on the same Write/Edit/MultiEdit event — a write
that satisfies plugin #1's SLA columns but omits plugin #3's playbook
escalation condition is refused by #3, independent of #1's pass. No
plugin needs to know the other five exist; the norm emerges from all
six being registered, exactly as the plugin list's composition column
states. This is the concrete answer to "어떤 플러그인들이 조합되어 그
규범이 성립하는지": the phase-2 norm *is* {#1 ∧ #2 ∧ #3 ∧ #4 ∧ #5 ∧ #7},
not a seventh thing that references them.

### 2.1 `customer-support-sla-tier` (#1)
**Gate**: a markdown table header containing all 6 required column
labels (case-insensitive: "priority", one of "impact", one of
"urgency", "first response", "resolution", "escalation trigger").
Missing → `missing.append("sla-table-column:<name>")`.
**Directive fragment**: every row must derive from an **ITIL
Impact×Urgency priority matrix** pair, not assert a tier label with no
pair behind it — named explicitly here (not only by reference to
`docs/issue-1/proposals/customer-support.md` §3), per the ITIL
service-desk incident-prioritization convention (impact × urgency →
priority; ManageEngine/InvGate/Freshworks ITIL problem/incident-
management guides, cited in scout-brief's re-scout addendum).
Kill switch: `CUSTOMER_SUPPORT_SLA_TIER_GATE_OFF=1`.

### 2.2 `customer-support-escalation-path` (#2)
**Gate**: for text under an "escalation path" heading, each tier
row/block must contain "trigger" (or equivalent), a named owner
(non-generic — "the team" alone fails; requires a role/title-shaped
token adjacent to "owner:" or a so-labeled table column), and "timeout"
(or equivalent). Missing → `missing.append("escalation-field:<name>")`.
**Directive fragment**: PROHIBITED — a bare "escalate to manager if
unresolved" line with no named owner/timeout.
Kill switch: `CUSTOMER_SUPPORT_ESCALATION_PATH_GATE_OFF=1`.

### 2.3 `customer-support-playbook-scenario` (#3)
**Gate**: for each detected scenario block (heading matching
`Scenario` or a bullet list under "playbook"), require "trigger"/
"scenario", "decision criteria", "script"/"response template"/
"response", and "escalation condition". Missing any →
`missing.append("playbook-element:<name>")`.
**Directive fragment**: PROHIBITED — a script with no escalation
condition, or an escalation condition naming no tier defined by plugin
#2's output.
Kill switch: `CUSTOMER_SUPPORT_PLAYBOOK_SCENARIO_GATE_OFF=1`.

### 2.4 `customer-support-evidence-metric` (#4)
**Gate**: at least one of "csat", "fcr", "first contact resolution",
"sla-adherence", "sla adherence" present. Missing →
`missing.append("evidence-metric")`.
**Directive fragment**: PROHIBITED — citing a metric by name with no
sentence connecting it to what the deliverable does to move it.
Kill switch: `CUSTOMER_SUPPORT_EVIDENCE_METRIC_GATE_OFF=1`.

### 2.5 `customer-support-five-whys` (#5) — reconsidered, retained with an explicit scope bound
**Reconsideration** (domain review, PR #11): ITIL problem-management
practice treats 5-whys as one of several root-cause-analysis
techniques alongside Ishikawa/fishbone and Kepner-Tregoe, and is
explicit that 5-whys "is best used on simple to moderately difficult
problems" and tends to miss root causes on problems with more than one
causal chain (per scout-brief's re-scout addendum, sourced from
InvGate/Kepner-Tregoe problem-management technique comparisons). This
role's segment (single-operator support desk deciding "hand off or
not," not running formal problem management against a KEDB) is exactly
the "simple to moderately difficult" case the technique fits — so
5-whys stays adopted, but the directive-level judgment must now state
the bound instead of presenting 5-whys as ITIL's uncontested default.
**Gate**: fires only when new content contains "repeat"/"recurring"
language in a scenario/entry context; when it does, requires "5-whys"
(or "five whys") plus 5 distinct question-shaped lines (heuristic: ≥5
lines ending in `?`) in the same section. Missing →
`missing.append("5-whys-check")`. Unchanged from the prior draft — the
scope bound below is a directive-level judgment call, not a new gate
check (the gate can only verify shape/presence, per open question 2).
**Directive fragment**: PROHIBITED — writing "hand off to
product-discovery" for a flagged-repeat entry with no 5-whys answers
preceding it in the same entry. **New**: a recurring pattern whose
5-whys answers do not converge on one causal chain (i.e. the "why"
lines branch into multiple unrelated causes rather than one chain)
must route to product-discovery on that basis alone — forcing a single
strained 5-whys narrative onto a multi-cause pattern is itself a
violation of the technique's own documented limits, not a compliant
use of it.
**Checklist** (`checklists/5-whys-recurring.md`): verbatim-copies the 5
questions already adopted in `docs/issue-1/proposals/
customer-support.md` §2 / `handbook.md` §5, plus one line stating the
scope bound above. Content promoted from embedded prose to a
referenceable artifact, not a new claim. Referenced by path from this
plugin's directive fragment. No `agents/` addition: the procedure is
content-authoring, not an autonomous subagent task (unlike, e.g.,
`warrant`'s hunt dispatch, which has no analog in this role's
deliverable shape).
Kill switch: `CUSTOMER_SUPPORT_FIVE_WHYS_GATE_OFF=1`.

### 2.6 `customer-support-kcs` (#7) — new, KCS Content Standard article shape
**Adoption basis** (domain review, PR #11): KCS (Knowledge-Centered
Service, Consortium for Service Innovation, KCS® registered service
mark) is the canonical methodology for a support role whose stated
`PRODUCES` is knowledge content (playbook/handbook), not only ticket
handling — per scout-brief's re-scout addendum. KCS's **Content
Standard** defines the article shape this plugin enforces: **Issue**
(the problem as experienced), **Environment** (scope/context), **
Resolution** (the fix), **Cause** (root cause, when known — the same
slot 5-whys' output feeds), **Metadata** (a reuse/lifecycle state
field). This does not replace the existing playbook-scenario shape
(#3, trigger/decision-criteria/script/escalation-condition) — it is
the *article-content* standard that scenario entries in `handbook.md`
must additionally satisfy once written, the same way #1's SLA columns
and #3's scenario elements both target overlapping write surfaces
without one subsuming the other.
**Gate**: for each handbook article/scenario entry (same detection
heuristic as #3: heading matching `Scenario` or a bullet list under
"playbook"), require all 5 KCS Content Standard labels present
(case-insensitive: "issue", "environment", "resolution", "cause",
"metadata" or "state"/"maturity" as a metadata-shaped field). Missing
any → `missing.append("kcs-element:<name>")`.
**Directive fragment**: PROHIBITED — a resolution with no environment
scope (a fix stated as universally applicable when it is conditional),
or a cause field left blank on an entry that also carries a 5-whys
block from plugin #5 (the 5-whys output must populate this field, not
sit orphaned in prose).
Kill switch: `CUSTOMER_SUPPORT_KCS_GATE_OFF=1`.

Each gate's deny message keeps the prior draft's specificity-per-element
shape: `"<plugin-name>: refused — <facet> write is missing required
element(s): <list>. Per docs/issue-1/proposals/customer-support.md §2,
every phase-2 deliverable/record write must carry: <full requirement
text>."` Each fails closed on unparseable payload (`exit 2`).

## 3. Ordering beyond phase-1 (#6) — not added elsewhere, reasoned

Per scout-brief's skip pattern: no plugin above adds a `warrant`-style
cross-session state-rebuild script. Plugin #6 covers the only
genuinely new ordering question (survey → scout-brief → proposal,
same-PR, same-session); the phase-1/phase-2 boundary is already
mechanically enforced by core's `approval-gate.sh`/`board-gate.sh`
(unchanged, out of scope). Adding a state-tracker to any of #1–#5 or #7
would be disproportionate — none of the six phase-2 elements has a
cross-session ordering requirement (a handbook write either has all of
a facet's elements or it doesn't; there is no "must come after"
relationship among SLA table / escalation path / playbook / metric /
5-whys / KCS article shape). Flagged as a future extension point on
plugin #6 specifically
if a future issue finds proposals written before surveys exist in
practice — not built now absent evidence of that failure.

## 4. Gate tests — one root-level file per plugin

Per the issue's explicit instruction ("레포 루트 tests"), seven new files,
each independently runnable (`bash tests/<plugin>-gate-tests.sh`), same
invocation model as core's `run-role-gates-tests.sh` (synthetic
PreToolUse JSON on stdin, `CLAUDE_ROLE=customer-support`,
`CLAUDE_PROJECT_DIR` set to a temp git-initialized dir):

- `tests/customer-support-sla-tier-gate-tests.sh`
- `tests/customer-support-escalation-path-gate-tests.sh`
- `tests/customer-support-playbook-scenario-gate-tests.sh`
- `tests/customer-support-evidence-metric-gate-tests.sh`
- `tests/customer-support-five-whys-gate-tests.sh`
- `tests/customer-support-phase1-order-gate-tests.sh`
- `tests/customer-support-kcs-gate-tests.sh`

Each file carries its own plugin's pass/deny cases (one deny case per
required element, isolated by removing exactly one element from a full
pass-case fixture), plus the shared cases every gate needs: kill-switch
off regardless of content, malformed-JSON fail-closed, and a
non-Write/Edit/MultiEdit `tool_name` passing through untouched (out of
gate scope). The five-whys file's pass-case fixture comment notes the
§2.5 scope bound (multi-cause 5-whys blocks route to product-discovery)
explicitly as a directive-level judgment the gate script does not and
cannot check — documented in the fixture so the boundary between gate
and directive enforcement stays visible at the test layer, not silently
assumed. No shared test harness file
is introduced — seven self-contained test files, not one parameterized
runner, matching the plugin-per-methodology principle at the test layer
too. Wired into a root `tests/run-all.sh` if/when more root-level test
files exist.

## Phase-2 write set

- `customer-support-sla-tier/.claude-plugin/plugin.json` — new
- `customer-support-sla-tier/hooks/{directive-fragment.sh,gate.sh,hooks.json}` — new
- `customer-support-escalation-path/.claude-plugin/plugin.json` — new
- `customer-support-escalation-path/hooks/{directive-fragment.sh,gate.sh,hooks.json}` — new
- `customer-support-playbook-scenario/.claude-plugin/plugin.json` — new
- `customer-support-playbook-scenario/hooks/{directive-fragment.sh,gate.sh,hooks.json}` — new
- `customer-support-evidence-metric/.claude-plugin/plugin.json` — new
- `customer-support-evidence-metric/hooks/{directive-fragment.sh,gate.sh,hooks.json}` — new
- `customer-support-five-whys/.claude-plugin/plugin.json` — new
- `customer-support-five-whys/hooks/{directive-fragment.sh,gate.sh,hooks.json}` — new
- `customer-support-five-whys/checklists/5-whys-recurring.md` — new
- `customer-support-phase1-order/.claude-plugin/plugin.json` — new
- `customer-support-phase1-order/hooks/{directive-fragment.sh,gate.sh,hooks.json}` — new
- `customer-support-kcs/.claude-plugin/plugin.json` — new
- `customer-support-kcs/hooks/{directive-fragment.sh,gate.sh,hooks.json}` — new
- `.claude-plugin/marketplace.json` — edit, register the seven new
  plugin entries (§0)
- `tests/customer-support-{sla-tier,escalation-path,playbook-scenario,evidence-metric,five-whys,phase1-order,kcs}-gate-tests.sh` — new, seven files
- `docs/issue-10/reports/customer-support.md` — new, phase-2 record

No change to `customer-support/hooks/directive.sh` or
`customer-support/hooks/hooks.json` (existing role plugin's identity/
hand-off content is unaffected — the seven methodology plugins stack on
top, per §0's composition column) and no change to core
(`record-fields-gate.sh` stays canon-referenced, unmodified).

## Open questions for approver

1. **Deliverable file path** (carried over unresolved from
   `docs/issue-1/proposals/customer-support.md`): all five phase-2
   plugins' gate regexes cover both the current single-file
   `handbook.md` and a possible future per-issue split. If phase 2
   changes the deliverable location, each of the five plugins' target-
   path regex needs the same update in parallel — flagged so the
   approver can confirm the regex shape before phase 2 builds five
   gates against it instead of one.
2. **5-whys detection heuristic**: "5 lines ending in `?` within the
   same section" is a shape check, not a semantic one — same
   presence-not-correctness trade-off `pricing/hooks/methodology-gate.sh`
   accepts. Flagged for awareness, not proposed as a blocker.
3. **Seven-plugin overhead**: seven `plugin.json`/`hooks.json` pairs
   (vs. the prior draft's one file) is more registration surface for
   the same enforcement content. Flagged in case the approver wants a
   coarser split (e.g. one plugin per phase instead of per facet) —
   this revision defaults to per-facet because the issue's "요구 정정"
   states the granularity explicitly ("방법론 1개 = 독립 플러그인 1개"),
   and each of the five §2 facets plus KCS is independently adopted —
   the five from `docs/issue-1/proposals/customer-support.md` §3 (each
   with its own scout-brief citation), KCS from this revision's
   scout-brief re-scout addendum — so each is a distinct "방법론" by
   the same document's evidentiary boundary.
4. **KCS/playbook-scenario overlap** (new, this revision): #3
   (playbook-scenario) and #7 (KCS) both gate content inside the same
   scenario-entry blocks with partially distinct but related element
   sets (§2.6 notes KCS's Cause slot is fed by #5's 5-whys output, and
   KCS's Resolution/Issue overlap conceptually with #3's script/
   trigger). Both gates fire independently and neither depends on the
   other's pass/fail, per §2's stated composition model — flagged so
   the approver can confirm two co-firing gates on the same entry
   shape is the intended granularity, rather than merging KCS's
   Content Standard fields into plugin #3 as additional required
   elements of the existing playbook-scenario check.

This PR is phase-1 (proposal) only. Phase 2 opens only after an
approvers.md account's PR-review Approve, or the exact-string
`APPROVE issue-10/customer-support` issue comment.
