import 'package:flutter_invoice_app/core/utils/number_to_words.dart';

void main() {
  print('--- Integer ---');
  print('"${NumberToWords.convert(105)}"');

  print('\n--- Decimal ---');
  print('"${NumberToWords.convert(10.50)}"');
  print('"${NumberToWords.convert(0.25)}"');
  print('"${NumberToWords.convert(100.99)}"');

  print('\n--- Currency ---');
  print('"${NumberToWords.convert(10.50, currencyCode: 'USD')}"');
  print('"${NumberToWords.convert(123.45, currencyCode: 'INR')}"');
}
