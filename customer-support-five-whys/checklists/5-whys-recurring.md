# 5-whys check for recurring inbound patterns

Any playbook scenario or report entry that identifies a **repeat
inbound pattern** must run this lightweight 5-whys check before
deciding whether to hand off to product-discovery or keep it as a
support-side scenario. This is intentionally limited to five questions
— it is not full SRE-style postmortem tooling (no incident commander
roles, no timestamped timeline reconstruction):

1. Why are customers hitting this? (What are they trying to do?)
2. Why doesn't the current product flow/documentation prevent the confusion or error?
3. Why hasn't this been fixed already — is it a known limitation, a regression, or new?
4. Why would a support-side workaround (macro, doc update, script) not be sufficient going forward?
5. Why would fixing this require product/engineering change rather than a support process change?

If the answer to (5) is "yes, it requires a product change," hand off
to product-discovery. Otherwise, keep it as a support-side scenario
and add/update a playbook entry and response script instead.

**§2.5 scope bound**: if the answers to (1)–(5) do not converge on one
causal chain — the "why" lines branch into multiple unrelated causes
rather than one chain — route to product-discovery on that basis
alone, rather than forcing a single strained 5-whys narrative onto a
multi-cause pattern.
