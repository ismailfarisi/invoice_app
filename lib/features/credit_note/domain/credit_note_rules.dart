import 'dart:math' as math;

import 'package:flutter_invoice_app/features/credit_note/domain/models/credit_note.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';

/// An invoice line and how much of it can still be credited.
class CreditableLine {
  final LineItem line;
  final double remainingAmount;

  const CreditableLine({required this.line, required this.remainingAmount});

  double get remainingQuantity => remainingAmount / line.unitPrice;
}

/// Credit already issued against invoices, split by whether the invoice was
/// paid, because each side reduces a different dashboard figure.
class CreditTotals {
  final double onPaidInvoices;
  final double onUnpaidInvoices;

  const CreditTotals({
    required this.onPaidInvoices,
    required this.onUnpaidInvoices,
  });

  double get all => onPaidInvoices + onUnpaidInvoices;
}

class CreditNoteRules {
  /// Amounts below this are treated as zero when comparing money.
  static const double tolerance = 0.005;

  static final RegExp _numberPattern = RegExp(r'^CN-(\d+)$');

  static bool canCredit(Invoice invoice) {
    return invoice.status == InvoiceStatus.sent ||
        invoice.status == InvoiceStatus.paid ||
        invoice.status == InvoiceStatus.overdue;
  }

  /// The VAT rate the invoice was actually charged at. The business's default
  /// rate may have changed since the invoice was issued.
  static double vatRateOf(Invoice invoice) {
    if (!(invoice.isVatApplicable ?? true) || invoice.subtotal <= 0) return 0;
    final rate = invoice.taxAmount / invoice.subtotal * 100;
    return (rate * 10000).roundToDouble() / 10000;
  }

  /// Numbers are sequential and voided notes keep theirs.
  static String nextNumber(Iterable<CreditNote> notes) {
    var highest = 0;
    for (final note in notes) {
      final match = _numberPattern.firstMatch(note.creditNoteNumber);
      if (match != null) {
        highest = math.max(highest, int.parse(match.group(1)!));
      }
    }
    return 'CN-${(highest + 1).toString().padLeft(4, '0')}';
  }

  /// Lines that still have value left to credit. Saved invoice lines have no
  /// stable id, so earlier credits are matched by description, in line order.
  static List<CreditableLine> creditableLines(
    Invoice invoice,
    Iterable<CreditNote> notes,
  ) {
    final credited = <String, double>{};
    for (final note in _activeFor(invoice.id, notes)) {
      for (final item in note.items) {
        final key = _lineKey(item);
        credited[key] = (credited[key] ?? 0) + item.total;
      }
    }

    final result = <CreditableLine>[];
    for (final line in invoice.items) {
      if (line.total <= 0) continue;
      final key = _lineKey(line);
      final used = math.min(credited[key] ?? 0.0, line.total);
      credited[key] = (credited[key] ?? 0) - used;
      final remaining = line.total - used;
      if (remaining > tolerance) {
        result.add(CreditableLine(line: line, remainingAmount: remaining));
      }
    }
    return result;
  }

  /// Net of VAT, how much of the invoice has not been credited yet.
  static double remainingSubtotal(Invoice invoice, Iterable<CreditNote> notes) {
    final credited = _activeFor(
      invoice.id,
      notes,
    ).fold(0.0, (sum, note) => sum + note.subtotal);
    return math.max(0.0, invoice.subtotal - credited);
  }

  static Map<String, double> creditedByInvoice(Iterable<CreditNote> notes) {
    final result = <String, double>{};
    for (final note in notes.where((n) => !n.isVoided)) {
      result[note.invoiceId] = (result[note.invoiceId] ?? 0) + note.total;
    }
    return result;
  }

  /// A credit note against a draft or cancelled invoice has no effect: those
  /// invoices are not counted, so subtracting the credit would count it twice.
  static bool affectsBalance(CreditNote note, Invoice? invoice) {
    if (note.isVoided) return false;
    if (invoice == null) return true;
    return invoice.status != InvoiceStatus.draft &&
        invoice.status != InvoiceStatus.cancelled;
  }

  static CreditTotals totals(
    Iterable<Invoice> invoices,
    Iterable<CreditNote> notes,
  ) {
    final invoicesById = {for (final i in invoices) i.id: i};
    var onPaid = 0.0;
    var onUnpaid = 0.0;
    for (final note in notes) {
      final invoice = invoicesById[note.invoiceId];
      if (invoice == null || !affectsBalance(note, invoice)) continue;
      if (invoice.status == InvoiceStatus.paid) {
        onPaid += note.total;
      } else {
        onUnpaid += note.total;
      }
    }
    return CreditTotals(onPaidInvoices: onPaid, onUnpaidInvoices: onUnpaid);
  }

  static Iterable<CreditNote> _activeFor(
    String invoiceId,
    Iterable<CreditNote> notes,
  ) {
    return notes.where((n) => n.invoiceId == invoiceId && !n.isVoided);
  }

  static String _lineKey(LineItem item) {
    return item.description.trim().toLowerCase();
  }
}
