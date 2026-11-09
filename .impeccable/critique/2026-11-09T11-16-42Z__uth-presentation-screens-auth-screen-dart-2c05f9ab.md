---
target: lib/features/auth/presentation/screens/auth_screen.dart
total_score: 19
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 2
target_identity: "file:C:\\Users\\Keerthana\\invoice_app\\lib\\features\\auth\\presentation\\screens\\auth_screen.dart"
target_fingerprint: "sha256:350b67030845a364307d5b2e89bfd30bd62459be366ce74469d50cc61879a863"
target_path: "C:\\Users\\Keerthana\\invoice_app\\lib\\features\\auth\\presentation\\screens\\auth_screen.dart"
timestamp: 2026-11-09T11-16-42Z
slug: uth-presentation-screens-auth-screen-dart-2c05f9ab
---
Method: design review only (detector not applicable, native platform)
Target: auth_screen.dart (pre-fix review). Score 19/40.
Heuristics: 1=2 2=2 3=2 4=2 5=1 6=3 7=1 8=3 9=1 10=2 
P1: raw "Error: $e" shown on network failure (line 61); sync failure after sign-in reported as error; no field validation.
P2: Colors.red snackbar; no tooltip on back; hard-coded greys break dark desktop; no autofill, next/done actions, or submit key; sign-in copy implies account is required; sign-up/in toggle target under 48dp.
