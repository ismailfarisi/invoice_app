import 'package:flutter_invoice_app/features/credit_note/domain/credit_note_rules.dart';
import 'package:flutter_invoice_app/features/credit_note/domain/models/credit_note.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';

class CustomerStatementItem {
  final String invoiceId;
  final String invoiceNumber;
  final DateTime date;
  final DateTime? dueDate;

  /// Null on credit note rows, which have no invoice status.
  final InvoiceStatus? status;
  final bool isCreditNote;
  final double amount;
  final double paidAmount;
  final double balance;
  final double runningBalance;

  CustomerStatementItem({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.date,
    this.dueDate,
    required this.status,
    this.isCreditNote = false,
    required this.amount,
    required this.paidAmount,
    required this.balance,
    required this.runningBalance,
  });

  String get statusLabel =>
      isCreditNote ? 'CREDIT NOTE' : (status?.name.toUpperCase() ?? '');
}

class CustomerStatement {
  final Client client;
  final DateTime statementDate;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<CustomerStatementItem> items;
  final double totalInvoiced;
  final double totalCredited;
  final double totalPaid;
  final double totalBalanceDue;
  final String currency;

  CustomerStatement({
    required this.client,
    required this.statementDate,
    this.fromDate,
    this.toDate,
    required this.items,
    required this.totalInvoiced,
    this.totalCredited = 0,
    required this.totalPaid,
    required this.totalBalanceDue,
    this.currency = 'AED',
  });

  /// Invoiced less credited, so the statement's amount column adds up.
  double get netInvoiced => totalInvoiced - totalCredited;

  bool get hasCreditBalance => totalBalanceDue < 0;

  String get balanceLabel => hasCreditBalance ? 'Credit Balance' : 'Balance Due';

  /// What the balance figure shows beside [balanceLabel].
  double get balanceAmount => totalBalanceDue.abs();

  factory CustomerStatement.fromInvoices({
    required Client client,
    required List<Invoice> allInvoices,
    List<CreditNote> creditNotes = const [],
    DateTime? fromDate,
    DateTime? toDate,
    DateTime? statementDate,
  }) {
    final now = statementDate ?? DateTime.now();

    bool isThisClient(Client other) {
      final matchesId = other.id == client.id;
      final matchesName =
          other.name.trim().toLowerCase() == client.name.trim().toLowerCase();
      return matchesId || matchesName;
    }

    bool isInPeriod(DateTime date) {
      if (fromDate != null &&
          date.isBefore(DateTime(fromDate.year, fromDate.month, fromDate.day))) {
        return false;
      }
      if (toDate != null &&
          date.isAfter(DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999))) {
        return false;
      }
      return true;
    }

    final invoicesById = {for (final inv in allInvoices) inv.id: inv};

    final entries = <_StatementEntry>[
      for (final inv in allInvoices)
        if (isThisClient(inv.client) &&
            inv.status != InvoiceStatus.draft &&
            inv.status != InvoiceStatus.cancelled &&
            isInPeriod(inv.date ?? now))
          _StatementEntry(date: inv.date ?? now, invoice: inv),
      for (final note in creditNotes)
        if (isThisClient(note.client) &&
            CreditNoteRules.affectsBalance(note, invoicesById[note.invoiceId]) &&
            isInPeriod(note.date))
          _StatementEntry(date: note.date, creditNote: note),
    ];

    // On the same day an invoice comes before the credit raised against it.
    entries.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return (a.creditNote == null ? 0 : 1).compareTo(b.creditNote == null ? 0 : 1);
    });

    double running = 0.0;
    double sumInvoiced = 0.0;
    double sumCredited = 0.0;
    double sumPaid = 0.0;
    String detectedCurrency = 'AED';
    if (entries.isNotEmpty) {
      final first = entries.first;
      final currency = first.invoice?.currency ?? first.creditNote?.currency;
      if (currency != null && currency.isNotEmpty) {
        detectedCurrency = currency;
      }
    }

    final List<CustomerStatementItem> items = [];
    for (final entry in entries) {
      final note = entry.creditNote;
      if (note != null) {
        final amount = -note.total;
        running = _tidy(running + amount);
        sumCredited += note.total;

        items.add(
          CustomerStatementItem(
            invoiceId: note.id,
            invoiceNumber: note.creditNoteNumber,
            date: note.date,
            status: null,
            isCreditNote: true,
            amount: amount,
            paidAmount: 0.0,
            balance: amount,
            runningBalance: running,
          ),
        );
        continue;
      }

      final inv = entry.invoice!;
      final amount = inv.total;
      final paid = inv.status == InvoiceStatus.paid ? amount : 0.0;
      final balance = amount - paid;
      running = _tidy(running + balance);
      sumInvoiced += amount;
      sumPaid += paid;

      items.add(
        CustomerStatementItem(
          invoiceId: inv.id,
          invoiceNumber: inv.invoiceNumber,
          date: inv.date ?? now,
          dueDate: inv.dueDate,
          status: inv.status,
          amount: amount,
          paidAmount: paid,
          balance: balance,
          runningBalance: running,
        ),
      );
    }

    return CustomerStatement(
      client: client,
      statementDate: now,
      fromDate: fromDate,
      toDate: toDate,
      items: items,
      totalInvoiced: sumInvoiced,
      totalCredited: sumCredited,
      totalPaid: sumPaid,
      totalBalanceDue: _tidy(sumInvoiced - sumPaid - sumCredited),
      currency: detectedCurrency,
    );
  }

  /// Clears floating point residue so a settled balance can't print as -0.00.
  static double _tidy(double value) {
    return value.abs() < CreditNoteRules.tolerance ? 0.0 : value;
  }
}

class _StatementEntry {
  final DateTime date;
  final Invoice? invoice;
  final CreditNote? creditNote;

  const _StatementEntry({required this.date, this.invoice, this.creditNote});
}
