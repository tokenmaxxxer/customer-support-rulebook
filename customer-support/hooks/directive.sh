#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive "YOU DECIDE: 문의를 어떤 우선순위/SLA로 처리할지" "USE WHEN: CS 플로우/SLA 설계가 걸릴 때" "PRODUCES: support playbook, SLA table, escalation path" "HAND-OFF: 반복 문의가 제품 결함이면 → product-discovery"
