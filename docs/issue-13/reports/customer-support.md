# Record: gate A+ remediation via gate-lib reference-adopt (issue-13)

Subject: issue-13. Phase-2 delivery, on the same branch/PR as the
approved proposal (`docs/issue-13/proposals/customer-support.md`).
Opened by the `APPROVE issue-13/customer-support` issue comment
(single-account mode, `JiwonJung94` on `docs/specs/approvers.md`).

loop_state: landed

## Why

The 2026-08-01 code audit graded this repo's seven gate scripts C+:
relative-path-only anchors left them production-inoperative against
absolute `file_path` values, no fail-closed trap meant any unexpected
abort (missing `jq`, unset var) silently fail-opened, and every
substring "semantic" check (e.g. KCS's `grep -qi cause`) passed on a
bare word mention with no structural relationship to the field it was
meant to guard. `tokenmaxxxer-core` issue-72 landed a shared gate-lib
(`gate-lib.sh`/`.py`) precisely to fix this defect class once,
canonically, instead of each rulebook re-deriving its own fix — this
delivery adopts that library by reference (never reimplemented) per
the approved proposal's §3, then layers this rulebook's own
section/adjacency semantic upgrade (§4) on top, since gate-lib does
not cover facet-level content matching.

## What was done

All seven `customer-support-*/hooks/*-gate.sh` scripts (renamed from a
bare `gate.sh` to `<name>-gate.sh` so `core`'s own
`compliance-check.sh` — which globs `*-gate.sh` — can find and verify
them) now:

- Source `core/hooks/lib/gate-lib.sh` via
  `${CLAUDE_PLUGIN_ROOT_CORE:-<sibling ../../core>}`, install
  `gate_trap_fail_closed` as the first statement (fail-closed on any
  unexpected abort), and call `gate_kill_switch_active` (unrecognized
  kill-switch values now provably stay active — regression-tested).
- Normalize every candidate `file_path` via `gate_normalize_path`
  before anchoring the target-path regex, so absolute and
  `./`-prefixed forms match identically to a bare relative path
  (survey.md defect 1, fixed and regression-tested per gate).
- Reconstruct `Write`/`Edit`/`MultiEdit` content via
  `gate_reconstruct_write` (correctly honoring `replace_all` on both
  single-`Edit` and mixed-`MultiEdit` calls) instead of checking only
  the call's own fragment.
- Deny via `gate_deny`'s stderr + exit-2 convention, replacing the
  stdout-JSON + exit-0 shape entirely (no downstream consumer depended
  on the JSON body — none of the seven old test suites asserted on it).
- Deny (rather than silently pass) a `Bash`-tool write whose command
  targets the same governed file, since the gate cannot reconstruct a
  Bash-written file's resulting content to check it — refusing an
  unverifiable write is the fail-closed posture, not a gap.

Semantic upgrade (proposal §4, this rulebook's own design — outside
gate-lib's scope per scout-brief.md): a new shared local helper,
`customer-support/hooks/lib/semantic.py`, provides section-slicing
(markdown-heading-scoped and table-header-row-scoped) and
paragraph-adjacency matching. Applied per gate: `kcs` and
`playbook-scenario` now require each field as its own labeled line
(`^\s*cause\s*:`, not a substring anywhere), fixing the confirmed
"no separate cause *because* it's covered above" false-pass;
`sla-tier` checks column names in the table's own header row, not
anywhere in the document; `escalation-path` scopes trigger/owner/
timeout to the Escalation Path section's own slice;
`phase1-order` requires the citation marker within the same paragraph
as the claim it backs, not merely present anywhere in the document.
`evidence-metric` and `five-whys` needed no structural change per the
proposal (their existing shape was not flagged as a substring-false-
positive risk) and were migrated to gate-lib as-is.

### Tests

All seven `tests/customer-support-<plugin>-gate-tests.sh` suites
rewritten against the new stderr+exit-2 deny convention, sharing a new
`tests/lib/harness.sh` (run_case/run_case_reason/make_payload/
make_edit_payload/make_multiedit_payload/make_bash_payload/seed_file).
Every suite now carries, per issue-13's requirement 3 and the
gate-house standard's six mandatory case groups: an `Edit`
`replace_all: true` case against a multiply-occurring `old_string`, a
`MultiEdit` case with mixed `replace_all` true/false edits, three
malformed-JSON sub-cases (truncated/non-JSON, empty payload, non-object
top level), a kill-switch-set-to-an-unrecognized-value case asserting
the gate stays active, three path forms (relative/absolute/
`./`-prefixed), a `Bash`-tool write reaching the same governed target,
plus one semantic-upgrade regression case per applicable gate (content
with the keyword in the wrong place — the case the pre-issue-13
substring check would have silently passed).

Full suite, run this session via
`bash tests/customer-support-<plugin>-gate-tests.sh` for each of the
seven files: 17 + 14 + 15 + 18 + 16 + 18 + 20 = 118 cases, 0 failures.
`core/hooks/tests/compliance-check.sh` run against this repo's
`hooks/` (via a local `tokenmaxxxer-core` checkout) reports `ok` for
all seven gate scripts — no hand-rolled kill-switch case statement, no
un-migrated `.replace()` reconstruction detected.

### README sync

Removed the three ghost file references
(`record-fields-gate.sh`/`trailer-gate.sh`/`handbook-trigger-gate.sh`,
confirmed absent from `customer-support/hooks/`) and added a table of
the seven real gate plugins, their renamed gate scripts, and their
kill-switch env vars, plus a note that they source
`core/hooks/lib/gate-lib.sh` by reference, not vendor.

## Evidence-metric mechanism

This delivery's SLA-adherence relevance: the fail-closed-trap and
absolute-path-normalization fixes stop gates from silently no-op'ing
on writes that would otherwise slip an SLA-tier or escalation-path
violation past the enforcement layer entirely (survey.md's "prod
무동작" finding) — a gate that fails open on an unexpected abort or
never matches an absolute path is a gate that cannot actually hold the
line on SLA-adherence, so hardening it to fail-closed and
path-normalized is what makes the SLA-tier/escalation-path plugins'
own SLA-adherence enforcement (issue-10) actually operative in
production rather than theoretical.

## Deviations from the proposal, and why

- **Gate scripts renamed** `gate.sh` → `<name>-gate.sh` (not mentioned
  in the proposal). `core/hooks/tests/compliance-check.sh` — the
  delivery-evidence tool the proposal's §5 and §8 both name — globs
  `*-gate.sh` and found zero matches under the old `gate.sh` naming;
  renaming was necessary for compliance-check.sh to see these gates at
  all, not an optional polish. `hooks.json` and every test file's
  `GATE=` path were updated to match.
- **Shared local semantic helper** (`customer-support/hooks/lib/
  semantic.py`) used by four gates (kcs, playbook-scenario, sla-tier,
  escalation-path), exceeding the proposal §4's "~2 gates" threshold
  for when a shared helper is justified over per-gate inline logic —
  evaluated during this phase-2 build per the proposal's own deferral,
  and four gates sharing identical slice logic justified the shared
  file over four inline copies.
- **`evidence-metric`/`five-whys` deny-message shape unchanged** from
  their pre-issue-13 substring check, since the proposal's §4 scope
  explicitly lists only kcs/playbook-scenario/sla-tier/escalation-path/
  phase1-order as needing the section/adjacency upgrade.

## Open findings

None outstanding. All seven gates migrated, all seven test suites
green (118/118), `compliance-check.sh` clean, README synced.
