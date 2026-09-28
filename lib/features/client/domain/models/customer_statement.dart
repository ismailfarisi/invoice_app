import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';

class CustomerStatementItem {
  final String invoiceId;
  final String invoiceNumber;
  final DateTime date;
  final DateTime? dueDate;
  final InvoiceStatus status;
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
    required this.amount,
    required this.paidAmount,
    required this.balance,
    required this.runningBalance,
  });
}

class CustomerStatement {
  final Client client;
  final DateTime statementDate;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<CustomerStatementItem> items;
  final double totalInvoiced;
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
    required this.totalPaid,
    required this.totalBalanceDue,
    this.currency = 'AED',
  });

  factory CustomerStatement.fromInvoices({
    required Client client,
    required List<Invoice> allInvoices,
    DateTime? fromDate,
    DateTime? toDate,
    DateTime? statementDate,
  }) {
    final now = statementDate ?? DateTime.now();

    final clientInvoices = allInvoices.where((inv) {
      final matchesId = inv.client.id == client.id;
      final matchesName =
          inv.client.name.trim().toLowerCase() == client.name.trim().toLowerCase();
      return matchesId || matchesName;
    }).where((inv) {
      return inv.status != InvoiceStatus.draft &&
          inv.status != InvoiceStatus.cancelled;
    }).where((inv) {
      final invDate = inv.date ?? now;
      if (fromDate != null &&
          invDate.isBefore(DateTime(fromDate.year, fromDate.month, fromDate.day))) {
        return false;
      }
      if (toDate != null &&
          invDate.isAfter(DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999))) {
        return false;
      }
      return true;
    }).toList();

    clientInvoices.sort((a, b) {
      final dateA = a.date ?? now;
      final dateB = b.date ?? now;
      return dateA.compareTo(dateB);
    });

    double running = 0.0;
    double sumInvoiced = 0.0;
    double sumPaid = 0.0;
    String detectedCurrency = 'AED';
    if (clientInvoices.isNotEmpty &&
        clientInvoices.first.currency != null &&
        clientInvoices.first.currency!.isNotEmpty) {
      detectedCurrency = clientInvoices.first.currency!;
    }

    final List<CustomerStatementItem> items = [];
    for (final inv in clientInvoices) {
      final amount = inv.total;
      final paid = inv.status == InvoiceStatus.paid ? amount : 0.0;
      final balance = amount - paid;
      running += balance;
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
      totalPaid: sumPaid,
      totalBalanceDue: sumInvoiced - sumPaid,
      currency: detectedCurrency,
    );
  }
}
