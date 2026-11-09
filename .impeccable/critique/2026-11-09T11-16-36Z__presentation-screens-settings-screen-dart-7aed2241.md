---
target: lib/features/settings/presentation/screens/settings_screen.dart
total_score: 24
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
target_identity: "file:C:\\Users\\Keerthana\\invoice_app\\lib\\features\\settings\\presentation\\screens\\settings_screen.dart"
target_fingerprint: "sha256:07a5bfad13300b1a46b01a9c54b7479c718b2a6ee189ca00d4557988e4d6525a"
target_path: "C:\\Users\\Keerthana\\invoice_app\\lib\\features\\settings\\presentation\\screens\\settings_screen.dart"
timestamp: 2026-11-09T11-16-36Z
slug: presentation-screens-settings-screen-dart-7aed2241
---
Method: design review only (detector not applicable, native platform)
Target: settings_screen.dart (pre-fix review). Score 24/40.
Heuristics: 1=2 2=2 3=2 4=3 5=2 6=3 7=2 8=3 9=1 10=2
P1: save rebuilt the profile and dropped userId/updatedAt (line ~105); async picker/save/sync calls unguarded; raw exception text in export/import/sync errors (lines 143, 205, 315).
P1: logo picker GestureDetector, no ripple/focus/label (line 398).
P2: Colors.green/grey hard-coded (251, 324, 615, 628); sign out had no tooltip/confirm (257); user.email! crash; IFSC hint and "Tax ID" wrong for UAE; no keyboard types; currency dropdown can crash on unknown stored value; section title can overflow.
P3: no unsaved-changes guard on back; no way to remove logo or key file.
