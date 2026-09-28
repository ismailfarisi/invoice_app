import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/client/domain/models/customer_statement.dart';

void main() {
  final testClient = Client(
    id: 'client-1',
    name: 'Acme Corp',
    email: 'billing@acme.com',
    phone: '+971501234567',
    address: 'Dubai, UAE',
    taxId: '100200300400003',
  );

  final otherClient = Client(
    id: 'client-2',
    name: 'Beta Ltd',
    email: 'info@beta.com',
  );

  Invoice createInvoice({
    required String id,
    required String number,
    required Client client,
    required DateTime date,
    required double total,
    required InvoiceStatus status,
  }) {
    return Invoice(
      id: id,
      invoiceNumber: number,
      client: client,
      date: date,
      dueDate: date.add(const Duration(days: 30)),
      items: [],
      subtotal: total,
      taxAmount: 0.0,
      discount: 0.0,
      total: total,
      status: status,
      currency: 'AED',
    );
  }

  group('CustomerStatement.fromInvoices', () {
    test('calculates totals, paid, and balance due correctly while filtering clients and excluding draft/cancelled', () {
      final invoices = [
        createInvoice(
          id: 'inv-1',
          number: 'INV-001',
          client: testClient,
          date: DateTime(2026, 1, 10),
          total: 1000.0,
          status: InvoiceStatus.paid,
        ),
        createInvoice(
          id: 'inv-2',
          number: 'INV-002',
          client: testClient,
          date: DateTime(2026, 2, 15),
          total: 2500.0,
          status: InvoiceStatus.sent,
        ),
        createInvoice(
          id: 'inv-3',
          number: 'INV-003',
          client: testClient,
          date: DateTime(2026, 3, 1),
          total: 500.0,
          status: InvoiceStatus.draft, // should be excluded
        ),
        createInvoice(
          id: 'inv-4',
          number: 'INV-004',
          client: testClient,
          date: DateTime(2026, 3, 5),
          total: 800.0,
          status: InvoiceStatus.cancelled, // should be excluded
        ),
        createInvoice(
          id: 'inv-5',
          number: 'INV-005',
          client: otherClient, // different client
          date: DateTime(2026, 3, 10),
          total: 3000.0,
          status: InvoiceStatus.sent,
        ),
        createInvoice(
          id: 'inv-6',
          number: 'INV-006',
          client: testClient,
          date: DateTime(2026, 3, 20),
          total: 1200.0,
          status: InvoiceStatus.overdue,
        ),
      ];

      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: invoices,
        statementDate: DateTime(2026, 3, 28),
      );

      expect(statement.items.length, 3);
      // Item 1: INV-001 (paid)
      expect(statement.items[0].invoiceNumber, 'INV-001');
      expect(statement.items[0].amount, 1000.0);
      expect(statement.items[0].paidAmount, 1000.0);
      expect(statement.items[0].balance, 0.0);
      expect(statement.items[0].runningBalance, 0.0);

      // Item 2: INV-002 (sent)
      expect(statement.items[1].invoiceNumber, 'INV-002');
      expect(statement.items[1].amount, 2500.0);
      expect(statement.items[1].paidAmount, 0.0);
      expect(statement.items[1].balance, 2500.0);
      expect(statement.items[1].runningBalance, 2500.0);

      // Item 3: INV-006 (overdue)
      expect(statement.items[2].invoiceNumber, 'INV-006');
      expect(statement.items[2].amount, 1200.0);
      expect(statement.items[2].paidAmount, 0.0);
      expect(statement.items[2].balance, 1200.0);
      expect(statement.items[2].runningBalance, 3700.0);

      // Totals
      expect(statement.totalInvoiced, 4700.0);
      expect(statement.totalPaid, 1000.0);
      expect(statement.totalBalanceDue, 3700.0);
      expect(statement.currency, 'AED');
    });

    test('respects date range filters correctly', () {
      final invoices = [
        createInvoice(
          id: 'inv-1',
          number: 'INV-001',
          client: testClient,
          date: DateTime(2026, 1, 10),
          total: 1000.0,
          status: InvoiceStatus.paid,
        ),
        createInvoice(
          id: 'inv-2',
          number: 'INV-002',
          client: testClient,
          date: DateTime(2026, 2, 15),
          total: 2000.0,
          status: InvoiceStatus.sent,
        ),
        createInvoice(
          id: 'inv-3',
          number: 'INV-003',
          client: testClient,
          date: DateTime(2026, 3, 20),
          total: 3000.0,
          status: InvoiceStatus.sent,
        ),
      ];

      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: invoices,
        fromDate: DateTime(2026, 2, 1),
        toDate: DateTime(2026, 2, 28),
      );

      expect(statement.items.length, 1);
      expect(statement.items.first.invoiceNumber, 'INV-002');
      expect(statement.totalInvoiced, 2000.0);
      expect(statement.totalPaid, 0.0);
      expect(statement.totalBalanceDue, 2000.0);
    });

    test('matches client by name if id is different or empty', () {
      final legacyClient = Client(
        id: 'legacy-id',
        name: 'Acme Corp',
        email: 'legacy@acme.com',
      );
      final invoices = [
        createInvoice(
          id: 'inv-1',
          number: 'INV-001',
          client: legacyClient,
          date: DateTime(2026, 1, 10),
          total: 1500.0,
          status: InvoiceStatus.sent,
        ),
      ];

      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: invoices,
      );

      expect(statement.items.length, 1);
      expect(statement.totalInvoiced, 1500.0);
    });
  });
}
