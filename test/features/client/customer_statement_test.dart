import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_invoice_app/features/credit_note/domain/models/credit_note.dart';
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

  group('CustomerStatement.fromInvoices with credit notes', () {
    CreditNote createNote({
      String number = 'CN-0001',
      String invoiceId = 'inv-1',
      Client? client,
      DateTime? date,
      double total = 400.0,
      bool isVoided = false,
    }) {
      return CreditNote(
        id: number,
        creditNoteNumber: number,
        date: date ?? DateTime(2026, 2, 1),
        invoiceId: invoiceId,
        invoiceNumber: 'INV-001',
        client: client ?? testClient,
        items: [],
        subtotal: total,
        vatRate: 0,
        taxAmount: 0,
        total: total,
        reason: 'Order cancelled',
        isVoided: isVoided,
      );
    }

    Invoice sentInvoice({InvoiceStatus status = InvoiceStatus.sent}) {
      return createInvoice(
        id: 'inv-1',
        number: 'INV-001',
        client: testClient,
        date: DateTime(2026, 1, 10),
        total: 1000.0,
        status: status,
      );
    }

    test('a partial credit reduces what an unpaid invoice still owes', () {
      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: [sentInvoice()],
        creditNotes: [createNote()],
      );

      expect(statement.items.length, 2);
      expect(statement.items[1].isCreditNote, isTrue);
      expect(statement.items[1].invoiceNumber, 'CN-0001');
      expect(statement.items[1].statusLabel, 'CREDIT NOTE');
      expect(statement.items[1].amount, -400.0);
      expect(statement.items[1].balance, -400.0);
      expect(statement.items[1].runningBalance, 600.0);
      expect(statement.totalInvoiced, 1000.0);
      expect(statement.totalCredited, 400.0);
      expect(statement.netInvoiced, 600.0);
      expect(statement.totalBalanceDue, 600.0);
      expect(statement.balanceLabel, 'Balance Due');
    });

    test('a full credit on a paid invoice leaves a credit balance', () {
      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: [sentInvoice(status: InvoiceStatus.paid)],
        creditNotes: [createNote(total: 1000.0)],
      );

      expect(statement.totalBalanceDue, -1000.0);
      expect(statement.items.last.runningBalance, -1000.0);
      expect(statement.hasCreditBalance, isTrue);
      expect(statement.balanceLabel, 'Credit Balance');
      expect(statement.balanceAmount, 1000.0);
    });

    test('a full credit on an unpaid invoice settles to exactly zero', () {
      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: [sentInvoice()],
        creditNotes: [createNote(total: 1000.0 + 1e-10)],
      );

      expect(statement.totalBalanceDue, 0.0);
      expect(statement.items.last.runningBalance, 0.0);
      expect(statement.balanceLabel, 'Balance Due');
    });

    test('a credit dated the same day follows its invoice', () {
      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: [sentInvoice()],
        creditNotes: [createNote(date: DateTime(2026, 1, 10))],
      );

      expect(statement.items[0].isCreditNote, isFalse);
      expect(statement.items[1].isCreditNote, isTrue);
    });

    test('ignores voided notes and notes for other customers', () {
      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: [sentInvoice()],
        creditNotes: [
          createNote(isVoided: true),
          createNote(number: 'CN-0002', client: otherClient),
        ],
      );

      expect(statement.items.length, 1);
      expect(statement.totalCredited, 0.0);
      expect(statement.totalBalanceDue, 1000.0);
    });

    test('does not subtract a credit against a cancelled invoice twice', () {
      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: [sentInvoice(status: InvoiceStatus.cancelled)],
        creditNotes: [createNote(total: 1000.0)],
      );

      expect(statement.items, isEmpty);
      expect(statement.totalBalanceDue, 0.0);
    });

    test('applies the period to the credit note date', () {
      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: [sentInvoice()],
        creditNotes: [createNote(date: DateTime(2026, 3, 15))],
        fromDate: DateTime(2026, 1, 1),
        toDate: DateTime(2026, 1, 31),
      );

      expect(statement.items.length, 1);
      expect(statement.totalCredited, 0.0);
    });
  });
}
