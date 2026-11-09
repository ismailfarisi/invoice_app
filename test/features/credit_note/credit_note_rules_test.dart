import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_invoice_app/features/credit_note/domain/credit_note_rules.dart';
import 'package:flutter_invoice_app/features/credit_note/domain/models/credit_note.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';

void main() {
  final client = Client(id: 'c1', name: 'Acme Corp', email: 'a@acme.com');

  LineItem line(String description, double quantity, double unitPrice) {
    return LineItem(
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      total: quantity * unitPrice,
    );
  }

  Invoice invoice({
    String id = 'inv-1',
    InvoiceStatus status = InvoiceStatus.sent,
    List<LineItem>? items,
    double taxAmount = 50,
    bool isVatApplicable = true,
  }) {
    final lines = items ?? [line('Widget', 10, 50), line('Install', 1, 500)];
    final subtotal = lines.fold(0.0, (sum, l) => sum + l.total);
    return Invoice(
      id: id,
      invoiceNumber: 'INV-$id',
      client: client,
      items: lines,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discount: 0,
      total: subtotal + taxAmount,
      status: status,
      isVatApplicable: isVatApplicable,
    );
  }

  CreditNote note({
    String number = 'CN-0001',
    String invoiceId = 'inv-1',
    List<LineItem>? items,
    bool isVoided = false,
  }) {
    final lines = items ?? [line('Widget', 2, 50)];
    final subtotal = lines.fold(0.0, (sum, l) => sum + l.total);
    return CreditNote(
      id: number,
      creditNoteNumber: number,
      date: DateTime(2026, 3, 1),
      invoiceId: invoiceId,
      invoiceNumber: 'INV-$invoiceId',
      client: client,
      items: lines,
      subtotal: subtotal,
      vatRate: 5,
      taxAmount: subtotal * 0.05,
      total: subtotal * 1.05,
      reason: 'Goods returned',
      isVoided: isVoided,
    );
  }

  group('canCredit', () {
    test('allows issued invoices only', () {
      expect(CreditNoteRules.canCredit(invoice()), isTrue);
      expect(
        CreditNoteRules.canCredit(invoice(status: InvoiceStatus.paid)),
        isTrue,
      );
      expect(
        CreditNoteRules.canCredit(invoice(status: InvoiceStatus.overdue)),
        isTrue,
      );
      expect(
        CreditNoteRules.canCredit(invoice(status: InvoiceStatus.draft)),
        isFalse,
      );
      expect(
        CreditNoteRules.canCredit(invoice(status: InvoiceStatus.cancelled)),
        isFalse,
      );
    });
  });

  group('vatRateOf', () {
    test('derives the rate actually charged on the invoice', () {
      expect(CreditNoteRules.vatRateOf(invoice()), 5.0);
    });

    test('is zero when VAT does not apply', () {
      expect(
        CreditNoteRules.vatRateOf(
          invoice(isVatApplicable: false, taxAmount: 0),
        ),
        0,
      );
    });
  });

  group('nextNumber', () {
    test('starts at CN-0001', () {
      expect(CreditNoteRules.nextNumber([]), 'CN-0001');
    });

    test('follows the highest number and never reuses a voided one', () {
      expect(
        CreditNoteRules.nextNumber([
          note(number: 'CN-0001'),
          note(number: 'CN-0007', isVoided: true),
          note(number: 'something-else'),
        ]),
        'CN-0008',
      );
    });
  });

  group('creditableLines', () {
    test('offers every line in full when nothing was credited', () {
      final lines = CreditNoteRules.creditableLines(invoice(), []);

      expect(lines.length, 2);
      expect(lines[0].remainingAmount, 500);
      expect(lines[0].remainingQuantity, 10);
      expect(lines[1].remainingAmount, 500);
    });

    test('takes earlier credits off the matching line', () {
      final lines = CreditNoteRules.creditableLines(invoice(), [note()]);

      expect(lines[0].remainingAmount, 400);
      expect(lines[0].remainingQuantity, 8);
      expect(lines[1].remainingAmount, 500);
    });

    test('drops lines that are fully credited', () {
      final lines = CreditNoteRules.creditableLines(invoice(), [
        note(items: [line('Widget', 10, 50)]),
      ]);

      expect(lines.length, 1);
      expect(lines.single.line.description, 'Install');
    });

    test('ignores voided credit notes and other invoices', () {
      final lines = CreditNoteRules.creditableLines(invoice(), [
        note(isVoided: true),
        note(number: 'CN-0002', invoiceId: 'other'),
      ]);

      expect(lines[0].remainingAmount, 500);
    });

    test('spreads a credit across repeated lines in order', () {
      final repeated = invoice(
        items: [line('Widget', 2, 50), line('Widget', 2, 50)],
      );

      final lines = CreditNoteRules.creditableLines(repeated, [
        note(items: [line('Widget', 3, 50)]),
      ]);

      expect(lines.length, 1);
      expect(lines.single.remainingAmount, 50);
    });
  });

  group('remainingSubtotal', () {
    test('subtracts active credit notes only', () {
      expect(
        CreditNoteRules.remainingSubtotal(invoice(), [
          note(),
          note(number: 'CN-0002', isVoided: true),
        ]),
        900,
      );
    });
  });

  group('totals', () {
    test('splits credits by whether the invoice was paid', () {
      final totals = CreditNoteRules.totals(
        [
          invoice(id: 'paid', status: InvoiceStatus.paid),
          invoice(id: 'open'),
        ],
        [
          note(number: 'CN-0001', invoiceId: 'paid'),
          note(number: 'CN-0002', invoiceId: 'open'),
          note(number: 'CN-0003', invoiceId: 'open'),
        ],
      );

      expect(totals.onPaidInvoices, closeTo(105, 0.001));
      expect(totals.onUnpaidInvoices, closeTo(210, 0.001));
      expect(totals.all, closeTo(315, 0.001));
    });

    test('skips voided notes and cancelled invoices', () {
      final totals = CreditNoteRules.totals(
        [
          invoice(id: 'gone', status: InvoiceStatus.cancelled),
          invoice(id: 'open'),
        ],
        [
          note(number: 'CN-0001', invoiceId: 'gone'),
          note(number: 'CN-0002', invoiceId: 'open', isVoided: true),
        ],
      );

      expect(totals.all, 0);
    });
  });

  test('survives a JSON round trip', () {
    final original = note();

    final restored = CreditNote.fromJson(original.toJson());

    expect(restored.creditNoteNumber, 'CN-0001');
    expect(restored.invoiceId, 'inv-1');
    expect(restored.client.name, 'Acme Corp');
    expect(restored.items.single.description, 'Widget');
    expect(restored.vatRate, 5);
    expect(restored.total, closeTo(105, 0.001));
    expect(restored.isVoided, isFalse);
  });
}
