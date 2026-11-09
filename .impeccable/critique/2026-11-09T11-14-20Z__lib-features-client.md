---
target: lib/features/client
total_score: 24
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
target_identity: "file:C:\\Users\\Keerthana\\invoice_app\\lib\\features\\client"
timestamp: 2026-11-09T11-14-20Z
slug: lib-features-client
---
# Critique: lib/features/client (list, form, selector)
Design review from source (native Android; no detector).
Heuristics (0-4): 1 Visibility 3, 2 Match real world 2 (Tax ID/VAT vs TRN), 3 Control 2 (no undo on delete), 4 Consistency 3, 5 Error prevention 2, 6 Recognition 3, 7 Flexibility 2 (no search/sort), 8 Aesthetic 3, 9 Error recovery 2 (unawaited save), 10 Help 2 (empty state w/o guidance). Total 24/40.
P1 client_list_screen.dart:95 GestureDetector card, no ripple/focus/semantics.
P1 client_list_screen.dart:161 delete icon-only, no tooltip, red.shade300 low contrast.
P1 client_form_screen.dart:42 edit save drops userId/updatedAt of the existing record.
P2 client_form_screen.dart:106,142 whitespace-only name passes; email not format-checked; no trim.
P2 client_form_screen.dart:56 async save not awaited/no error handling.
P2 client_list_screen.dart:35-51 empty state hard-coded greys, no guidance.
P2 client_list_screen.dart:136 long name no ellipsis; list padding hides last card behind FAB (:55).
P2 client_list_screen.dart:176 delete dialog doesn't name company, hard-coded red.
P2 client_form_screen.dart:113 "Tax ID / VAT" vs product term TRN; no textCapitalization/textInputAction.
P2 client_selector.dart:21 empty state only a disabled dropdown, no hint how to add.
P3 unsorted list, no search; sheet handle grey.shade300 (dark mode); no unsaved-changes guard.
