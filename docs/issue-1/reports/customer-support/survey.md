---
subject: issue-1
role: customer-support
loop_state: open
---

# Current-state survey (issue-1, role: customer-support)

## What exists in this repo today

- `customer-support/hooks/directive.sh` — already migrated to the core
  stub shape (post issue-2 phase 2): sources
  `core/hooks/lib/role-directive.sh` and calls `core_role_directive`
  with exactly 4 fields:
  - `YOU DECIDE: 문의를 어떤 우선순위/SLA로 처리할지`
  - `USE WHEN: CS 플로우/SLA 설계가 걸릴 때`
  - `PRODUCES: support playbook, SLA table, escalation path`
  - `HAND-OFF: 반복 문의가 제품 결함이면 → product-discovery`

  None of these four fields specify *how* priority/SLA is decided, what
  columns an SLA table must have, what fields an escalation path must
  have, or what evidence a playbook must cite. They name the decision
  and the deliverables, not the methodology behind either.

- `customer-support/hooks/hooks.json` — registers only `directive.sh`
  under `SessionStart`. No other hooks (no gate scripts remain locally;
  per issue-2's phase 2 the role-agnostic gates and warrant-hunter copy
  were already removed and are now referenced from core).

- `customer-support/.claude-plugin/plugin.json` — restates the same
  four-field contract in prose form (name/description/author only; no
  methodology or record-field schema).

- No `roles/customer-support.json` or other role-state config file
  exists in this repo.

- No record file yet exists for this role under `docs/issue-1/` or
  elsewhere (no prior `docs/issue-*/reports/customer-support.md`) — this
  is the first issue in this repo to define what that record must
  contain.

- No handbook, SLA-table template, escalation-path template, or
  playbook template exists anywhere in this repo for the
  customer-support role. Precedent proposals in this repo
  (`docs/issue-2/proposals/core-canon-reference-transition.md`,
  `docs/issue-5/proposals/stub-check-reclaim.md`) are both internal
  repo-canon migrations with no external methodology content — neither
  is a precedent for *what a CS playbook/SLA table should contain*,
  only for *proposal document shape* (phase-1/phase-2 split, write-set
  list, open-questions section).

## Delta this issue must fill

1. No proposal-norm exists for how a customer-support phase-1 proposal
   in this repo must be structured/evidenced (issue-1's own ask).
2. No deliverable-norm exists for what a phase-2 support
   playbook/SLA table/escalation path must structurally contain.
3. No mapping from adopted methodology back to this role's specific
   decision ("우선순위/SLA 처리") exists.
4. No concrete phase-2 write set (directive.sh field changes, record
   required fields, gate) has been proposed.

This survey is the base for `docs/issue-1/reports/customer-support/scout-brief.md`
(external methodology research) and `docs/issue-1/proposals/customer-support.md`
(the proposal filling the four gaps above).
