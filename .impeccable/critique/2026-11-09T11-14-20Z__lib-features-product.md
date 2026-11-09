---
target: lib/features/product
total_score: 23
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 6
target_identity: "file:C:\\Users\\Keerthana\\invoice_app\\lib\\features\\product"
timestamp: 2026-11-09T11-14-20Z
slug: lib-features-product
---
# Critique: lib/features/product (list, form, selector)
Heuristics (0-4): 1 3, 2 2, 3 2, 4 3, 5 1 (price accepts junk, saved as 0), 6 3, 7 2, 8 3, 9 2, 10 2. Total 23/40.
P1 product_list_screen.dart:165 price uses default $ not currency.
P1 product_selector.dart:102 hard-coded "$" price.
P1 product_form_screen.dart:40 invalid price ("abc", "1,200") silently saved as 0; negatives allowed.
P1 product_form_screen.dart:42 edit save drops userId/updatedAt.
P1 product_list_screen.dart:97 GestureDetector card no ripple/focus.
P1 product_list_screen.dart:172 delete icon-only, no tooltip, low-contrast red.
P2 product_list_screen.dart:143,164 long name / huge price overflow-prone.
P2 product_list_screen.dart:35-47 empty state hard-coded greys, no guidance.
P2 product_list_screen.dart:51 FAB overlaps last card; "No SKU" noise.
P2 product_selector.dart:27,59 nothing shown until typing; no "no match" state; add button has no tooltip.
P2 product_form_screen.dart:29 price shown as "10.0"; async save unawaited; sku/unit saved as '' not null.
P3 dead comments in ProductListScreen; no search on list.
