---
target: lib/features/quotation/presentation/screens/quotation_form_screen.dart
total_score: 25
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 6
target_identity: "file:C:\\Users\\Keerthana\\invoice_app\\lib\\features\\quotation\\presentation\\screens\\quotation_form_screen.dart"
target_fingerprint: "sha256:11e861a0e54fdc195d855d28f0aefe4545b154ecc85a8baae3ebf9967415dd4b"
target_path: "C:\\Users\\Keerthana\\invoice_app\\lib\\features\\quotation\\presentation\\screens\\quotation_form_screen.dart"
timestamp: 2026-11-09T11-13-23Z
slug: tation-screens-quotation-form-screen-dart-69cc4c3a
---
# Critique: quotation list / form / pdf preview (source review)

Scores (list / form / preview): H1 3/2/3, H2 3/3/3, H3 2/1/3, H4 3/3/3, H5 2/2/3, H6 3/3/3, H7 2/2/3, H8 3/2/3, H9 2/1/2, H10 2/2/2. Totals 25 / 21 / 28. Average 24.7.

P1 list:51 CurrencyFormatter.format(total) uses default $ not document currency.
P1 list:232 badge text Colors.green/orange on own tint fails contrast.
P1 list:123 GestureDetector card: no ripple, focus or semantics.
P2 list:167 client name no ellipsis; long names overflow beside amount.
P2 list:78 empty state gives no guidance and same message for every tab.
P2 list expired shown under Rejected tab with no label difference (left).
P1 form:126 save drops validUntil, notes, discount, isSynced, updatedAt, userId of existing record.
P1 form:70 edit uses profile default VAT rate not the quotation's own rate: reopening and saving silently changes tax/total.
P1 form:146 no error handling around async save.
P1 form: no unsaved-changes guard on back.
P2 form:182 PDF icon button no tooltip; 238 add-client button no tooltip.
P2 form:151 convert to invoice: no confirmation, no error handling; converts saved record not unsaved edits.
P2 form:269 status dropdown uppercase enum names; date shown as raw ISO.
P2 form:310 SwitchListTile fine; 337 date InkWell no radius/semantic.
P2 form:393 Items header not heading semantics; fixed-size text.
P3 form:49 default number is millisecond timestamp.
P2 preview: Excel export has no try/catch or feedback.
