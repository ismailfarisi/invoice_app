import 'dart:io';
import '../lib/core/utils/number_to_words.dart';

void main() async {
  final file = File('debug_output.txt');
  final sink = file.openWrite();

  void check(double amount, String expected) {
    final result = NumberToWords.convert(amount);
    if (result != expected) {
      sink.writeln('FAIL: $amount');
      sink.writeln('  Exp: "$expected"');
      sink.writeln('  Got: "$result"');
    } else {
      sink.writeln('PASS: $amountStr(amount) -> "$result"');
    }
  }

  sink.writeln('--- Debug Start ---');
  check(10.50, 'UAE Dirham Ten and Fifty Fils Only');
  check(0, 'UAE Dirham Zero Only');
  check(1, 'UAE Dirham One Only');
  check(15, 'UAE Dirham Fifteen Only');
  check(21, 'UAE Dirham Twenty One Only');
  check(105, 'UAE Dirham One Hundred and Five Only');
  check(1234, 'UAE Dirham One Thousand Two Hundred and Thirty Four Only');
  check(100.99, 'UAE Dirham One Hundred and Ninety Nine Fils Only');
  sink.writeln('--- Debug End ---');

  await sink.close();
}

String amountStr(double amount) {
  return amount.toString(); // Simple string rep
}
