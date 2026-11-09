---
target: lib/features/invoice/presentation/screens/delivery_note_list_screen.dart
total_score: 22
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 1
target_identity: "file:C:\\Users\\Keerthana\\invoice_app\\lib\\features\\invoice\\presentation\\screens\\delivery_note_list_screen.dart"
target_fingerprint: "sha256:9f2d9ed911778049eea0968d3ffb88483109be274edfc3b599435347f9e4215c"
target_path: "C:\\Users\\Keerthana\\invoice_app\\lib\\features\\invoice\\presentation\\screens\\delivery_note_list_screen.dart"
timestamp: 2026-11-09T11-14-36Z
slug: on-screens-delivery-note-list-screen-dart-294556ef
---
Method: design review only (detector not applicable, native platform)

Delivery note list (22/40) and letterhead input (21/40); average 22/40.

Delivery list scores: 1:2 2:3 3:3 4:2 5:3 6:2 7:1 8:3 9:2 10:1 = 22
Letterhead scores:    1:2 2:3 3:2 4:2 5:2 6:2 7:2 8:3 9:2 10:1 = 21

Issues
- [P1] delivery:109 GestureDetector card: no ripple, no focus, no semantics for TalkBack.
- [P2] delivery:167 customer name has no maxLines/ellipsis; long names push the chevron.
- [P2] delivery:77,82 empty state hard-coded greys (dark mode), generic copy that does not say what to do.
- [P2] delivery:175 meta line hides invoice status; cancelled/draft invoices appear as deliverable with no cue. File name uses raw invoice number.
- [P2] delivery: bottom padding, tabs say Paid/Pending but list is of invoices (copy).
- [P2] letterhead:56 hint-only field (label vanishes on typing), OutlineInputBorder differs from the app's filled borderless fields, no explanation of what a letter head is or that blank is allowed.
- [P3] letterhead: no capitalisation, text lost silently on back.
- [P3] delivery: no search across many invoices.

Personas: Jordan - letterhead gives no hint what it will produce. Sam - delivery cards not exposed as buttons. Riley - long client names, no-date invoices.
