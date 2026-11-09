import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_invoice_app/features/credit_note/domain/models/credit_note.dart';
import 'package:flutter_invoice_app/features/credit_note/presentation/screens/credit_note_form_screen.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';

void main() {
  late Directory tempDir;
  late Box<CreditNote> creditNotes;

  final client = Client(id: 'c1', name: 'Acme Corp', email: 'a@acme.com');

  final invoice = Invoice(
    id: 'inv-1',
    invoiceNumber: 'INV-001',
    client: client,
    date: DateTime(2026, 1, 10),
    items: [
      LineItem(description: 'Widget', quantity: 10, unitPrice: 50, total: 500),
      LineItem(description: 'Install', quantity: 1, unitPrice: 500, total: 500),
    ],
    subtotal: 1000,
    taxAmount: 50,
    discount: 0,
    total: 1050,
    status: InvoiceStatus.paid,
  );

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_credit_note_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapter(InvoiceAdapter());
    Hive.registerAdapter(InvoiceStatusAdapter());
    Hive.registerAdapter(ClientAdapter());
    Hive.registerAdapter(LineItemAdapter());
    Hive.registerAdapter(BusinessProfileAdapter());
    Hive.registerAdapter(CreditNoteAdapter());
    creditNotes = await Hive.openBox<CreditNote>('credit_notes');
    await Hive.openBox<BusinessProfile>('settings');
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<void> pumpForm(
    WidgetTester tester, {
    Size size = const Size(1200, 1600),
    Invoice? form,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => creditNotes.clear());
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: CreditNoteFormScreen(invoice: form ?? invoice)),
      ),
    );
    await tester.pumpAndSettle();
  }

  String totalText(WidgetTester tester) {
    return tester
        .widget<Text>(find.byKey(const ValueKey('credit-note-total')))
        .data!;
  }

  testWidgets('starts as a full credit with VAT at the invoice rate', (
    tester,
  ) async {
    await pumpForm(tester);

    expect(find.text('CN-0001'), findsOneWidget);
    expect(find.text('VAT (5%)'), findsOneWidget);
    expect(totalText(tester), contains('1,050.00'));
  });

  testWidgets('removing a line and reducing quantity lowers the total', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.tap(find.byKey(const ValueKey('credit-select-1')));
    await tester.pump();
    expect(totalText(tester), contains('525.00'));

    await tester.enterText(
      find.byKey(const ValueKey('credit-quantity-0')),
      '2',
    );
    await tester.pump();
    expect(totalText(tester), contains('105.00'));
  });

  testWidgets('refuses a quantity above the invoiced quantity', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.text('Goods returned'));

    // 20 x 5 stays inside the 500 left on the line, but only 10 were invoiced.
    await tester.enterText(
      find.byKey(const ValueKey('credit-quantity-0')),
      '20',
    );
    await tester.enterText(find.byKey(const ValueKey('credit-rate-0')), '5');
    await tester.pump();

    expect(
      find.text('Quantity can\'t be more than the 10 invoiced.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Issue'));
    await tester.pump();
    expect(
      find.text('Correct the highlighted items before issuing.'),
      findsOneWidget,
    );
    expect(creditNotes.isEmpty, isTrue);
  });

  testWidgets('refuses a rate above the invoiced rate', (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.byKey(const ValueKey('credit-rate-0')), '51');
    await tester.pump();

    expect(
      find.text('Rate can\'t be more than the 50 invoiced.'),
      findsOneWidget,
    );
  });

  testWidgets('editing an item does not flag the untouched reason', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.enterText(
      find.byKey(const ValueKey('credit-quantity-0')),
      '2',
    );
    await tester.pump();

    expect(find.text('Enter the reason for this credit note'), findsNothing);
  });

  testWidgets('still requires a reason when it is scrolled off screen', (
    tester,
  ) async {
    final longInvoice = Invoice(
      id: 'inv-long',
      invoiceNumber: 'INV-LONG',
      client: client,
      items: [
        for (var i = 0; i < 12; i++)
          LineItem(
            description: 'Item $i',
            quantity: 1,
            unitPrice: 10,
            total: 10,
          ),
      ],
      subtotal: 120,
      taxAmount: 6,
      discount: 0,
      total: 126,
      status: InvoiceStatus.sent,
    );
    await pumpForm(tester, size: const Size(390, 844), form: longInvoice);

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -6000),
    );
    await tester.pump();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('credit-note-reason'))).dy,
      lessThan(0),
    );

    await tester.tap(find.text('Issue'));
    await tester.pump();

    expect(find.text('Add a reason before issuing.'), findsOneWidget);
    expect(creditNotes.isEmpty, isTrue);
  });

  testWidgets('needs a reason before it can be issued', (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Issue'));
    await tester.pump();

    expect(find.text('Enter the reason for this credit note'), findsOneWidget);
    expect(creditNotes.isEmpty, isTrue);
  });

  testWidgets('needs at least one line selected', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.text('Order cancelled'));
    await tester.tap(find.text('Clear All'));
    await tester.pump();

    await tester.tap(find.text('Issue'));
    await tester.pump();

    expect(find.text('Select at least one item to credit.'), findsOneWidget);
    expect(creditNotes.isEmpty, isTrue);
  });

  testWidgets('issues a partial credit note linked to the invoice', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.tap(find.text('Goods returned'));
    await tester.tap(find.byKey(const ValueKey('credit-select-1')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('credit-quantity-0')),
      '4',
    );
    await tester.pump();

    // Hive's write has to run on the real clock or it never completes.
    await tester.runAsync(() async {
      await tester.tap(find.text('Issue'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final note = creditNotes.values.single;
    expect(note.creditNoteNumber, 'CN-0001');
    expect(note.invoiceId, 'inv-1');
    expect(note.invoiceNumber, 'INV-001');
    expect(note.reason, 'Goods returned');
    expect(note.items.single.description, 'Widget');
    expect(note.items.single.quantity, 4);
    expect(note.subtotal, 200);
    expect(note.vatRate, 5);
    expect(note.taxAmount, closeTo(10, 0.0001));
    expect(note.total, closeTo(210, 0.0001));
    expect(note.isSynced, isFalse);
    expect(find.text('Credit Note CN-0001'), findsOneWidget);
  });

  test('a saved credit note is read back intact from disk', () async {
    await creditNotes.clear();
    final original = CreditNote(
      id: 'n1',
      creditNoteNumber: 'CN-0009',
      date: DateTime(2026, 3, 1),
      invoiceId: 'inv-1',
      invoiceNumber: 'INV-001',
      invoiceDate: DateTime(2026, 1, 10),
      client: client,
      items: [invoice.items.first],
      subtotal: 500,
      vatRate: 5,
      taxAmount: 25,
      total: 525,
      reason: 'Goods returned',
      currency: 'USD',
      placeOfSupply: 'Dubai',
      salesPerson: 'Sam',
      isVoided: true,
      isSynced: true,
      updatedAt: DateTime(2026, 3, 2),
      userId: 'u1',
    );
    await creditNotes.put(original.id, original);

    await creditNotes.close();
    creditNotes = await Hive.openBox<CreditNote>('credit_notes');

    final restored = creditNotes.get('n1')!;
    expect(restored.creditNoteNumber, 'CN-0009');
    expect(restored.date, DateTime(2026, 3, 1));
    expect(restored.invoiceDate, DateTime(2026, 1, 10));
    expect(restored.client.name, 'Acme Corp');
    expect(restored.items.single.description, 'Widget');
    expect(restored.vatRate, 5);
    expect(restored.total, 525);
    expect(restored.reason, 'Goods returned');
    expect(restored.currency, 'USD');
    expect(restored.placeOfSupply, 'Dubai');
    expect(restored.salesPerson, 'Sam');
    expect(restored.isVoided, isTrue);
    expect(restored.isSynced, isTrue);
    expect(restored.userId, 'u1');
  });

  testWidgets('lays out on a phone without overflow', (tester) async {
    await pumpForm(tester, size: const Size(360, 1800));

    expect(tester.takeException(), isNull);
    expect(find.text('Items to Credit'), findsOneWidget);
  });
}
