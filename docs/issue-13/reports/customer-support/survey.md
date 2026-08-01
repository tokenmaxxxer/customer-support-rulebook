# Survey — issue-13 (gate audit remediation, current grade C+)

## Scope
All seven `customer-support-*` plugins' `hooks/gate.sh` and their tests
under `tests/`, plus `README.md`.

## Defect inventory (confirmed by reading, not assumed from the issue text)

1. **Relative-path-only matching.** Every gate anchors `file_path` with a
   bare relative regex, e.g.
   `customer-support-phase1-order/hooks/gate.sh:23`:
   `^docs/issue-([0-9]+)/proposals/customer-support\.md$`. An absolute
   `file_path` (what `Write`/`Edit` tool_input carries when the caller
   passes an absolute path, which Claude Code does not forbid) never
   matches this anchor, so the gate silently no-ops in that case —
   "prod 무동작" per the issue. No gate normalizes to a root-relative
   path first.
2. **No fail-closed trap.** No `gate.sh` installs an `EXIT` trap. Each
   script runs under `set -u` (not `set -uo pipefail`) and checks `jq -e .`
   once for malformed JSON, but any other unexpected abort (missing `jq`
   binary, unset var under `-u`, a later `python3` failure) exits with
   whatever bash's default code is, which Claude Code's hook runner
   treats as **non-blocking** (fail-open) for anything other than exit
   0/2.
3. **Substring "semantic" checks.** `customer-support-kcs/hooks/gate.sh:66`:
   `grep -qi 'cause'` — a Cause field containing only the word "because"
   (e.g. "no separate cause because it's covered above") satisfies this
   check. Same substring-only shape recurs as `check_facet()` in
   `customer-support-phase1-order/hooks/gate.sh:50-57` (keyword mention
   anywhere in the diff satisfies the facet, regardless of section/
   adjacency to its citation) and equivalent per-facet greps in the other
   five gates.
4. **Deny reason delivery.** All seven gates return their PreToolUse deny
   reason via `hookSpecificOutput.permissionDecisionReason` on **stdout**
   with `exit 0` (`customer-support-phase1-order/hooks/gate.sh:69-87`,
   same shape elsewhere) rather than the `stderr` + `exit 2` convention
   the issue calls for and `gate-lib.sh`'s `gate_deny` implements.
5. **`Edit`/`MultiEdit`/`replace_all` reconstruction.** None of the seven
   gates reconstruct file content at all — each reads only the tool call's
   own `new_string`/`edits[].new_string` fragment(s)
   (`customer-support-phase1-order/hooks/gate.sh:42-47`) rather than the
   resulting file content, so a check that needs cross-fragment or
   whole-document context (e.g. "does this section already exist
   elsewhere in the file") cannot see it, and `replace_all` is never
   consulted.
6. **README ghost files.** `README.md`'s Layout section lists
   `customer-support/hooks/record-fields-gate.sh`,
   `customer-support/hooks/trailer-gate.sh`, and
   `customer-support/hooks/handbook-trigger-gate.sh` — none exist.
   `customer-support/hooks/` only contains `directive.sh` and
   `hooks.json`. The seven `customer-support-*-gate.sh` plugins and their
   kill-switch env vars are undocumented anywhere in `README.md`.

## Kill-switch check (per-gate)
All seven gates use `[[ "${X_GATE_OFF:-}" == "1" ]]` — i.e. only the
literal `1` disables, everything else (including a typo) stays active.
This is already the correct default-active direction (matches
`gate_kill_switch_active`'s fixed convention), unlike core's own
pre-issue-72 gates. Not a defect here, but must not regress when
migrating to `gate_kill_switch_active`.

## Test suite state
`tests/customer-support-*-gate-tests.sh` exist for all seven gates
(`customer-support-kcs-gate-tests.sh` read in full). None of the seven
suites include: an `Edit`/`MultiEdit` `replace_all` case, a malformed-JSON
case beyond the single "not valid JSON at all" shape, a kill-switch
unrecognized-value case, or an absolute/`./`-prefixed path case. This
matches `gate-house-standard.md`'s six mandatory case groups being wholly
absent from this repo's suites.

## Precondition status
`tokenmaxxxer/tokenmaxxxer-core` has `core/hooks/lib/gate-lib.sh` +
`gate-lib.py` + `docs/handbooks/gate-house-standard.md` merged
(issue-72, landed 2026-08-01) — confirmed by cloning and reading
directly. The precondition for issue-13 is satisfied.
