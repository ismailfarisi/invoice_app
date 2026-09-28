import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_invoice_app/features/client/presentation/screens/client_list_screen.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';

void main() {
  late Directory tempDir;
  late Box<Client> clientBox;
  late Box<Invoice> invoiceBox;
  late Box<BusinessProfile> settingsBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_client_list_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(InvoiceAdapter().typeId)) {
      Hive.registerAdapter(InvoiceAdapter());
    }
    if (!Hive.isAdapterRegistered(InvoiceStatusAdapter().typeId)) {
      Hive.registerAdapter(InvoiceStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(ClientAdapter().typeId)) {
      Hive.registerAdapter(ClientAdapter());
    }
    if (!Hive.isAdapterRegistered(LineItemAdapter().typeId)) {
      Hive.registerAdapter(LineItemAdapter());
    }
    if (!Hive.isAdapterRegistered(BusinessProfileAdapter().typeId)) {
      Hive.registerAdapter(BusinessProfileAdapter());
    }

    clientBox = await Hive.openBox<Client>('clients');
    invoiceBox = await Hive.openBox<Invoice>('invoices');
    settingsBox = await Hive.openBox<BusinessProfile>('settings');
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('renders empty state when there are no clients', (tester) async {
    await tester.runAsync(() async {
      await clientBox.clear();
      await invoiceBox.clear();
      await settingsBox.clear();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ClientListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No companies yet'), findsOneWidget);
    expect(find.text('Add Company'), findsOneWidget);
  });

  testWidgets(
      'displays statement action button and opens statement date filter bottom sheet',
      (tester) async {
    final client = Client(
      id: 'c1',
      name: 'Acme Industries',
      email: 'info@acme.com',
      contactPerson: 'John Doe',
      phone: '+971501234567',
    );

    await tester.runAsync(() async {
      await clientBox.clear();
      await clientBox.put(client.id, client);
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ClientListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify client card is shown
    expect(find.text('Acme Industries'), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);

    // Verify statement action button exists
    final statementButton = find.byTooltip('Statement of Account');
    expect(statementButton, findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);

    // Tap statement button
    await tester.tap(statementButton);
    await tester.pumpAndSettle();

    // Verify bottom sheet appears with expected header and options
    expect(find.text('Customer Statement - Acme Industries'), findsOneWidget);
    expect(find.text('All Time'), findsOneWidget);
    expect(find.text('This Month'), findsOneWidget);
    expect(find.text('This Year'), findsOneWidget);
    expect(find.text('Custom Range'), findsOneWidget);
    expect(find.text('View Statement'), findsOneWidget);

    // Select "This Month" filter chip
    await tester.tap(find.text('This Month'));
    await tester.pumpAndSettle();

    // Verify "This Month" choice chip is selected
    final thisMonthChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'This Month'),
    );
    expect(thisMonthChip.selected, isTrue);

    final allTimeChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'All Time'),
    );
    expect(allTimeChip.selected, isFalse);
  });

  testWidgets(
      'tapping View Statement generates statement and navigates to GenericPdfPreviewScreen',
      (tester) async {
    final client = Client(
      id: 'c2',
      name: 'Beta Global',
      email: 'contact@betaglobal.com',
    );

    await tester.runAsync(() async {
      await clientBox.clear();
      await clientBox.put(client.id, client);
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ClientListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap statement button
    final statementButton = find.byTooltip('Statement of Account');
    await tester.tap(statementButton);
    await tester.pumpAndSettle();

    // Tap "View Statement"
    final viewStatementButton = find.text('View Statement');
    await tester.tap(viewStatementButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify GenericPdfPreviewScreen is pushed with the statement title
    expect(find.text('Statement - Beta Global'), findsOneWidget);
  });
}
