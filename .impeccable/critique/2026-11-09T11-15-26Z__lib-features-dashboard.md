---
target: lib/features/dashboard
total_score: 25
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 7
target_identity: "file:C:\\Users\\Keerthana\\invoice_app\\lib\\features\\dashboard"
timestamp: 2026-11-09T11-15-26Z
slug: lib-features-dashboard
---
# Critique: lib/features/dashboard (avg of 4 files) - 25/40 before fixes

Scores (dashboard_screen / overview / mobile_menu / sync_indicator):
- Visibility of status: 3/2/3/2
- Match real world: 3/2/3/2 (Revenue Trend actually showed invoiced, not paid)
- User control: 3/2/3/2
- Consistency: 3/3/3/2
- Error prevention: 3/3/3/3
- Recognition: 3/3/3/2
- Flexibility: 2/2/2/2
- Minimalist: 3/2/3/3
- Error recovery: 3/2/3/1 (raw exception in snackbar)
- Help: 2/1/3/1 (no empty-state guidance)

P1: overview default $ currency (dashboard_overview.dart:127-148,359,621,791); white text on light-blue funnel bar overflowing off-bar (547,620); status badge text green/orange on own tint (369-378); dead "View All" button (203); stat grid overflows at large font scale (123); GestureDetector sidebar/menu with no ripple/focus (dashboard_screen.dart:307, mobile_menu.dart:139); hard-coded grey in dark mode (dashboard_screen.dart:318).
P2: no empty states (invoices, top clients); empty client name crashes avatar (780); long names overflow (339,787); sync error icon no tooltip, hard-coded red, raw exception text, 20dp indicator padding < 48dp; chevron 30% alpha too faint.
P3: Revenue chart axis label "0k" repeats; reversed.toList() inside builder.
