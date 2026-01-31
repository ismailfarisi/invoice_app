import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_invoice_app/core/utils/number_to_words.dart';

void main() {
  test('Integer conversions', () {
    expect(NumberToWords.convert(0), 'UAE Dirham Zero Only');
    expect(NumberToWords.convert(1), 'UAE Dirham One Only');
    expect(NumberToWords.convert(10), 'UAE Dirham Ten Only');
    expect(NumberToWords.convert(15), 'UAE Dirham Fifteen Only');
    expect(NumberToWords.convert(21), 'UAE Dirham Twenty One Only');
    expect(NumberToWords.convert(105), 'UAE Dirham One Hundred and Five Only');
    expect(
      NumberToWords.convert(1234),
      'UAE Dirham One Thousand Two Hundred and Thirty Four Only',
    );
    expect(NumberToWords.convert(10000), 'UAE Dirham Ten Thousand Only');
    expect(
      NumberToWords.convert(100000),
      'UAE Dirham One Hundred Thousand Only',
    );
  });

  test('Decimal conversions', () {
    expect(NumberToWords.convert(10.50), 'UAE Dirham Ten and Fifty Fils Only');
    expect(
      NumberToWords.convert(0.25),
      'UAE Dirham Zero and Twenty Five Fils Only',
    );
    expect(
      NumberToWords.convert(100.99),
      'UAE Dirham One Hundred and Ninety Nine Fils Only',
    );
  });
}
