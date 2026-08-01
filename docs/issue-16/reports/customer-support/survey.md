# Survey — issue-16 (gate A+ 최종 마감: 2026-08-01 재감사 잔여 결함)

## Scope
Common precondition state (core issue-75, on-the-record issue-182), all
seven `customer-support-*/hooks/*-gate.sh` scripts, their
`tests/customer-support-*-gate-tests.sh` suites, `README.md`, and each
plugin's `.claude-plugin/plugin.json` + the top-level marketplace
manifest.

## Precondition status (confirmed by direct read, not assumed)
- Core issue-75 (`tokenmaxxxer/tokenmaxxxer-core`, commit `52bdc15`,
  PR #77 "deliver(implementation): gate-lib source guard +
  gate_bash_write_targets py parity") is **landed**: `gate-lib.sh`'s
  usage comment now shows the mandatory guarded form
  (`. "$path" || { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }`),
  `compliance-check.sh` flags an unguarded source, `gate-lib.py` has
  `gate_bash_write_targets(command)` with sh/py parity, and
  `run-gate-lib-tests.sh` makes the `missing-core` case its 7th
  mandatory group (`docs/handbooks/gate-house-standard.md` §"Standard
  test harness", group 7; §"Transition note (issue-75...)").
- On-the-record issue-182 (`CLAUDE_PLUGIN_ROOT_CORE` injection in
  spawn.py) — not independently re-verified in this repo (out of this
  repo's write scope); this repo's gates already resolve
  `CLAUDE_PLUGIN_ROOT_CORE` with the documented sibling-directory
  fallback (`${CLAUDE_PLUGIN_ROOT_CORE:-$(cd .../../core && pwd -P)}`),
  which is the correct consumer-side shape regardless of whether the
  injection lands.

Both preconditions are satisfied for this repo to reference-adopt the
confirmed guard shape.

## Defect inventory (confirmed by reading every gate script, not assumed from the issue text)

1. **Unguarded `gate-lib.sh` source in all 7 gates — the exact issue-75
   defect, unfixed here.** Every one of
   `customer-support-{kcs,playbook-scenario,evidence-metric,five-whys,escalation-path,sla-tier,phase1-order}/hooks/*-gate.sh`
   opens with a bare
   `. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"`
   — no `||` fallback on the same statement. Confirmed via
   `grep -n "gate-lib.sh"` against all seven `*-gate.sh` files: the
   source line is present but unguarded in every one. Per
   `gate-house-standard.md`'s issue-75 finding, a `source` failure
   (core unreachable, e.g. sibling `../../core` missing and
   `CLAUDE_PLUGIN_ROOT_CORE` unset) defines no `gate_*` function, so the
   very next line, `gate_trap_fail_closed` (or a later
   `gate_kill_switch_active` call), fails with "command not found"
   (127) — read by Claude Code's hook runner as non-blocking, i.e. every
   one of this repo's seven gates silently no-ops when core is
   unreachable. This is the "common" defect the issue references
   ("공통 선행 조건... core#75... 참조 적용" — the precondition landed
   upstream, but this repo never re-pulled the guarded line).

2. **Bash-path scan diverges from `gate_lib.gate_bash_write_targets`
   (matcher-code parity gap).** All seven gates' Python payloads define
   their own `candidate_paths()` that, for `tool == "Bash"`, calls
   `re.findall(r'[\w./~-]+', tool_input.get("command", ""))` instead of
   the canon `gate_lib.gate_bash_write_targets(command)` (now available,
   sh/py-parity-tested, per issue-75). Two concrete divergences from the
   canon token set (`[A-Za-z0-9_./~$-]+` in both `gate-lib.sh`'s
   `grep -oE` and `gate-lib.py`'s `re.findall`):
   - `\w` already covers `[A-Za-z0-9_]` so no functional gap there, but
     the hand-rolled pattern **omits `$`** — a `Bash` command
     referencing a shell-variable path (e.g. `cat $HOME/docs/issue-16/...`
     or any command built from a variable, which the harness itself uses
     routinely — see `tests/lib/harness.sh`'s own `$CLAUDE_PLUGIN_ROOT_CORE`
     usage pattern) is not tokenized as containing that variable's
     literal text, but more importantly the omission means this repo's
     seven gates and core's own canon do not agree on what a
     "Bash write target" candidate token looks like for the *same*
     command string — exactly the parity core's group-6 mandatory test
     case (`bash-write-coverage` + sh/py parity assertion) exists to
     catch, and this repo's own test suites never run that parity
     assertion against its own gates (item 4 below).
   - hooks.json's matcher for all seven plugins is `".*"` (confirmed via
     `grep -n matcher` across all seven `hooks.json` files) — i.e. every
     tool call reaches the gate, and every gate's own
     `tool not in ("Write", "Edit", "MultiEdit", "Bash")` check
     correctly includes `Bash`. The matcher itself is not the gap; the
     gap is that the advertised (tested-by-core, documented-in-canon)
     Bash-path-scan implementation and this repo's actual
     production-reachable implementation are two different regexes,
     so a defect in either can silently diverge without either suite's
     tests catching it.

3. **No `missing-core` test case in any of the 7 suites.** Confirmed via
   `grep -n "missing-core\|CLAUDE_PLUGIN_ROOT_CORE"` against
   `tests/customer-support-five-whys-gate-tests.sh` (representative) and
   `tests/lib/harness.sh`: the harness only *resolves*
   `CLAUDE_PLUGIN_ROOT_CORE` for running tests against a real core
   checkout: it never asserts the gate's own behavior when
   `CLAUDE_PLUGIN_ROOT_CORE` points at a nonexistent path (core's
   group-7 mandatory case, `run-gate-lib-tests.sh`). Given finding 1
   (unguarded source), this repo's suites cannot currently prove the
   guard fires — there is no guard to prove, and no test that would
   catch its absence.

4. **README.md ghost item: `customer-support/agents/warrant-hunter.md`.**
   `README.md`'s Layout section (line 28) still lists
   `customer-support/agents/warrant-hunter.md — rotating-stance hunt
   agent`. Confirmed absent: `ls customer-support/agents/` fails with
   "no such file or directory" — the directory itself does not exist.
   Cross-referenced against this repo's own history:
   `docs/issue-2/reports/implementation.md` records "Deleted
   `customer-support/agents/warrant-hunter.md` — role now relies [on
   core's canonical `warrant` plugin]" as issue-2's delivered fix. The
   README line was never updated to match — a stale reference to a file
   removed three issues ago, one of the two items the issue text calls
   out by name outside the common precondition.

5. **Five-whys checklist/message consistency, checked in detail (the
   issue's second named item).** Compared
   `customer-support-five-whys/hooks/directive-fragment.sh` (the
   SessionStart message text) against
   `customer-support-five-whys/checklists/5-whys-recurring.md` (the
   detailed checklist it points to) and
   `customer-support-five-whys/hooks/five-whys-gate.sh` (the mechanical
   check that actually runs):
   - The checklist specifies **five fixed, causal-chain-specific
     questions** (checklist lines 10-14: "why are customers hitting
     this", "why doesn't the current flow prevent it", etc.) plus a
     `§2.5` scope-bound rule: if the five answers do not converge on one
     causal chain, route to product-discovery *on that basis alone*.
   - The gate's mechanical check (`five-whys-gate.sh:88-91`) only tests
     `has_label` (the literal string "5-whys"/"five whys" appears
     anywhere) `and question_count >= 5` (any line ending in `?`,
     anywhere in the content, via
     `re.findall(r'\?\s*$', content, re.MULTILINE)`) — it does not
     check that the five questions are *the checklist's five
     questions*, and it has **no mechanical check at all** for the
     `§2.5` convergence rule (whether the five answers actually
     converge on one chain vs. branch into unrelated causes). An entry
     could satisfy the gate with five unrelated question-shaped lines
     that never address causal convergence, then still record a
     hand-off decision the checklist's own `§2.5` would have routed
     differently.
   - This gap is not flagged anywhere as a known judgment-vs-mechanical
     split the way three sibling plugins do (see finding 6) — five-whys'
     `directive-fragment.sh` states the mechanical requirement
     ("five distinct question-shaped lines") as if it were the whole
     check, with no "the gate can only check X; Y is a judgment call"
     caveat, unlike `evidence-metric`'s and `escalation-path`'s
     fragments (finding 6's sibling pattern). This is the "메시지와
     불일치" the issue names: the deny message describes a shape check
     as though it enforces the checklist's actual causal-chain and
     `§2.5` requirements, which it does not.

6. **Stale `hooks/gate.sh` filename in three directive-fragment.sh
   messages (found while investigating finding 5, same class of
   defect).** `grep -rn "hooks/gate.sh" customer-support-*/hooks/directive-fragment.sh`
   matches three files —
   `customer-support-sla-tier/hooks/directive-fragment.sh:16`,
   `customer-support-evidence-metric/hooks/directive-fragment.sh:15`,
   `customer-support-escalation-path/hooks/directive-fragment.sh:12` —
   each stating "The gate script (`hooks/gate.sh`) only checks...".
   No such file exists in any of the seven plugins: every gate script
   was renamed to `hooks/<plugin-name>-gate.sh` (`sla-tier-gate.sh`,
   `evidence-metric-gate.sh`, `escalation-path-gate.sh` respectively) —
   confirmed present under those names, `hooks/gate.sh` confirmed
   absent in all three plugin directories. This is a second,
   independently-confirmed instance of the same "message references a
   file that isn't there" defect class as finding 4, this time in the
   SessionStart directive text shown to the operating agent every
   session rather than in README.

## Manifest / role-name audit (issue requirement 4)
- `.claude-plugin/marketplace.json`: all eight plugin entries
  (`customer-support`, and the seven `customer-support-*` gate plugins)
  use current names; no pre-round-3 or pre-issue-10 role name found.
- Each of the eight `*/.claude-plugin/plugin.json` files: name field
  matches its directory name (spot-checked `customer-support-five-whys`
  and `customer-support-kcs`; no divergent naming found in the
  `marketplace.json` cross-reference, which lists all eight by their
  actual directory-matching names).
- No ghost *files* found beyond README's warrant-hunter line (finding
  4) — `find . -type f` enumerated every file in the repo; every path
  under a plugin directory corresponds to a `hooks.json`-wired or
  `README`/`checklist`-referenced file except the one already-flagged
  README line.

## Test suite state
All seven `tests/customer-support-*-gate-tests.sh` exist and (per
issue-13's delivered record) were green with `compliance-check.sh`
passing at that time — but `compliance-check.sh`'s guard-detection
check (added in core issue-75, after issue-13 landed) has not been
re-run against this repo since: this repo's compliance status against
the **current** (issue-75-inclusive) `compliance-check.sh` is unproven,
and finding 1 predicts it would currently **fail** the unguarded-source
check.

## Scout-directive applicability
This is reference-adopt of an already-confirmed upstream fix
(core issue-75's guard shape and py-parity function) plus mechanical
doc/message cleanup — no open design decision comparable to a
build-a-new-mechanism call. See `scout-brief.md` for the recorded skip
and its one-line reason.
