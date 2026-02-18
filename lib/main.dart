import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/core/theme/app_theme.dart';
import 'package:flutter_invoice_app/features/dashboard/dashboard_screen.dart'; // We'll create this next
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/quotation/domain/models/quotation.dart';
import 'package:flutter_invoice_app/features/product/domain/models/product.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:flutter_invoice_app/features/lpo/domain/models/lpo.dart';
import 'package:flutter_invoice_app/features/proforma/domain/models/proforma.dart';
import 'package:flutter_invoice_app/core/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(InvoiceAdapter());
  Hive.registerAdapter(InvoiceStatusAdapter());
  Hive.registerAdapter(ClientAdapter());
  Hive.registerAdapter(LineItemAdapter());
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(BusinessProfileAdapter());
  Hive.registerAdapter(QuotationAdapter());
  Hive.registerAdapter(QuotationStatusAdapter());

  Hive.registerAdapter(LpoAdapter());
  Hive.registerAdapter(LpoStatusAdapter());
  Hive.registerAdapter(ProformaInvoiceAdapter());
  Hive.registerAdapter(ProformaStatusAdapter());

  // Open Boxes
  await Hive.openBox<Invoice>('invoices');
  await Hive.openBox<Quotation>('quotations');
  await Hive.openBox<Client>('clients');
  await Hive.openBox<Product>('products');
  await Hive.openBox<BusinessProfile>('settings');
  await Hive.openBox<Lpo>('lpos');
  await Hive.openBox<ProformaInvoice>('proformas');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize SyncService
    ref.read(syncServiceProvider);

    return MaterialApp(
      title: 'Flutter Invoice App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
