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
    // Note: The current implementation results in "UAE Dirham Ten and Fifty Fils Only"
    // The previous test expected "UAE Dirham Ten and Fifty Fils Only" which is correct.
    // Let's re-verify the exact output.
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

  test('Multi-currency conversions', () {
    expect(
      NumberToWords.convert(10.50, currencyCode: 'USD'),
      'US Dollar Ten and Fifty Cents Only',
    );
    expect(
      NumberToWords.convert(100.99, currencyCode: 'EUR'),
      'Euro One Hundred and Ninety Nine Cents Only',
    );
    expect(
      NumberToWords.convert(50, currencyCode: 'GBP'),
      'British Pound Fifty Only',
    );
    expect(
      NumberToWords.convert(123.45, currencyCode: 'INR'),
      'Indian Rupee One Hundred and Twenty Three and Forty Five Paise Only',
    );
  });
}
