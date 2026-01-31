class NumberToWords {
  static final _units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];

  static final _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  static final _scales = ['', 'Thousand', 'Million', 'Billion', 'Trillion'];

  static String convert(
    double amount, {
    String currency = 'UAE Dirham',
    String subunit = 'Fils',
  }) {
    if (amount == 0) return '$currency Zero Only';

    int integerPart = amount.floor();
    int decimalPart = ((amount - integerPart) * 100).round();

    // Fix for floating point precision issues (e.g. 19.9999999)
    if (decimalPart == 100) {
      integerPart++;
      decimalPart = 0;
    }

    String words = _convertNumber(integerPart);

    // Format: "UAE Dirham One Hundred and Fifty Fils Only"
    // Or if 0 fils: "UAE Dirham One Hundred Only"

    String result = '$currency $words';

    if (decimalPart > 0) {
      result += ' and ${_convertNumber(decimalPart)} $subunit';
    }

    return '$result Only';
  }

  static String _convertNumber(int number) {
    if (number == 0) return '';

    // Handles 0-999
    if (number < 20) {
      return _units[number];
    }

    if (number < 100) {
      return '${_tens[number ~/ 10]}${number % 10 > 0 ? ' ${_units[number % 10]}' : ''}';
    }

    if (number < 1000) {
      return '${_units[number ~/ 100]} Hundred${number % 100 > 0 ? ' and ${_convertNumber(number % 100)}' : ''}';
    }

    // Handles numbers >= 1000
    String words = '';
    int scaleIndex = 0;

    while (number > 0) {
      if (number % 1000 != 0) {
        String chunk = _convertNumber(number % 1000);
        if (_scales[scaleIndex].isNotEmpty) {
          chunk += ' ${_scales[scaleIndex]}';
        }
        words = chunk + (words.isNotEmpty ? ' $words' : '');
      }
      number ~/= 1000;
      scaleIndex++;
    }

    return words.trim();
  }
}
