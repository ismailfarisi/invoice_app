import 'package:flutter/material.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';

class FormTotalRow extends StatelessWidget {
  final String label;
  final double value;
  final String currency;

  const FormTotalRow({
    super.key,
    required this.label,
    required this.value,
    this.currency =
        'AED', // Default to AED if not specified, or match app default
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          CurrencyFormatter.format(value, symbol: currency),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
