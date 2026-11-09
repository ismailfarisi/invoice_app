---
target: lib/features/invoice/presentation/screens/invoice_form_screen.dart
total_score: 26
max_score: 40
na_heuristics: 
p0_count: 1
p1_count: 10
target_identity: "file:C:\\Users\\Keerthana\\invoice_app\\lib\\features\\invoice\\presentation\\screens\\invoice_form_screen.dart"
target_fingerprint: "sha256:9af9f01cc123ff334462777201ee17071df45b60b3d1a380fa77753f86e673f2"
target_path: "C:\\Users\\Keerthana\\invoice_app\\lib\\features\\invoice\\presentation\\screens\\invoice_form_screen.dart"
timestamp: 2026-11-09T11-13-24Z
slug: entation-screens-invoice-form-screen-dart-7cc260a8
---
Method: design review only (detector not applicable, native platform). Covers 4 pages; scores list/form/pdf_preview/generic = 26/24/25/28 (avg 26).

# Heuristics (list / form / pdf preview / generic)
1 Status: 2/2/2/3  2 Real world: 3/3/3/3  3 Control: 3/2/3/3  4 Consistency: 3/3/3/3  5 Error prevention: 3/2/3/3
6 Recognition: 3/3/3/3  7 Flexibility: 2/2/2/2  8 Minimalist: 3/3/4/4  9 Recovery: 2/2/1/2  10 Help: 2/2/2/2

# Issues
## invoice_form_screen.dart
- [P0] _save omits dueDate, notes, terms, userId, updatedAt (lines 147-169): editing wipes them.
- [P1] _vatRate always profile default (line 89): editing an old invoice at another rate silently changes total.
- [P1] _save has no try/catch, no double-tap guard, no success feedback (128-174).
- [P1] Back/system-back discards edits with no confirmation (Casey interrupted).
- [P1] PDF button previews the stored invoice, not unsaved edits (198-212); no tooltip. Add-client button no tooltip (255).
- [P2] Items with blank description can be saved (136).
- [P2] Dates shown as ISO text; new invoice date empty so list shows "No Date" (357).
- [P2] Items empty state has no guidance; Total Amount row can overflow with huge amounts (559-583).
- [P3] Save is top-right (not thumb zone); INV-<millis> default number; ItemCard ignores currency (shared).
## invoice_list_screen.dart
- [P1] Total uses default $ not invoice currency (200).
- [P1] Badge green/orange text on own tint fails contrast (224-235); overdue/cancelled look like pending.
- [P1] GestureDetector card: no ripple/focus/semantics (119).
- [P2] Long client names not truncated (167); amount column can overflow.
- [P2] Empty state hard-coded greys, no guidance, same copy for every tab (80-91).
- [P2] Cancelled invoices appear under Pending tab (51).
## pdf_preview_screen.dart
- [P1] Excel export has no error handling/feedback/mounted check (26-37).
- [P2] File name uses raw invoice number (path chars); no busy state for export.
## generic_pdf_preview_screen.dart
- [P3] Fine; Excel export is caller-owned. No issues in my scope.

# Personas
Casey: save top-of-screen, loses edits on back. Jordan: no guidance on empty items. Sam: card not focusable, low-contrast badges, no tooltips. Riley: long names, huge totals, foreign currency.
