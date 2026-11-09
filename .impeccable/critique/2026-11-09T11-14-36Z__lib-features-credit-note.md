---
target: lib/features/credit_note
total_score: 28
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 0
target_identity: "file:C:\\Users\\Keerthana\\invoice_app\\lib\\features\\credit_note"
timestamp: 2026-11-09T11-14-36Z
slug: lib-features-credit-note
---
Method: design review only (detector not applicable, native platform)

Credit note screens (list, form, preview). Averages: list 28, form 28, preview 28 => 28/40.

| # | Heuristic | List | Form | Preview |
|---|-----------|------|------|---------|
| 1 | Visibility of status | 3 | 2 (no saving indicator on Issue) | 3 |
| 2 | Real-world match | 3 | 3 | 3 |
| 3 | User control | 3 | 2 (no discard prompt on back) | 3 |
| 4 | Consistency | 3 | 3 | 3 |
| 5 | Error prevention | 3 | 3 (caps good; no confirm before Issue, which is permanent) | 3 |
| 6 | Recognition | 3 | 3 | 3 |
| 7 | Flexibility | 2 (no search on list) | 3 | 2 |
| 8 | Minimalist | 3 | 3 | 3 |
| 9 | Error recovery | 3 | 3 | 3 |
| 10 | Help | 2 | 3 | 2 |

Issues
- [P2] list:245 badge colours grey.shade800 / green.shade900 on a 10% tint of themselves: unreadable in dark mode.
- [P2] list:103,108 empty state hard-coded greys; break dark mode.
- [P2] list:68 list padding hides the last card under the FAB.
- [P2] list picker: no drag handle, long customer names, fixed 75% height ignores keyboard.
- [P2] form: Issue button gives no progress feedback while saving; leaving with edits discards silently.
- [P2] form:625-656 narrow layout: huge amount in an unconstrained Row child can overflow.
- [P2] form: when the reason is missing and off screen, only a snackbar says so; the field is not brought into view.
- [P2] preview: voided note looks identical to an issued one (title), void result has no confirmation.
- [P3] form date field InkWell has no radius; no search on credit note list.
- Decision: Issue is permanent but has no confirm step (existing test taps Issue and expects a saved note).

Personas: Casey - Issue is top-right, far from thumb (matches app convention). Jordan - reason chips help. Sam - fields have labels, checkbox labelled; badge contrast. Riley - long names ok on list, amount overflow on form.
