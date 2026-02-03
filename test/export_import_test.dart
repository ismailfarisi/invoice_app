import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:flutter_invoice_app/features/lpo/domain/models/lpo.dart';
import 'package:flutter_invoice_app/features/product/domain/models/product.dart';
import 'package:flutter_invoice_app/features/quotation/domain/models/quotation.dart';
import 'package:flutter_invoice_app/features/proforma/domain/models/proforma.dart';

void main() {
  test('Export and Import Logic Reproduction', () {
    // 1. Create Sample Data
    final sampleClient = Client(
      id: 'client-1',
      name: 'Test Client',
      email: 'test@client.com',
      address: '123 Test St',
    );

    final sampleLineItem = LineItem(
      description: 'Test Item',
      quantity: 1.0,
      unitPrice: 100.0,
      total: 100.0,
      id: 'item-1', // Assuming manually present for test
    );

    final sampleInvoice = Invoice(
      id: 'inv-1',
      invoiceNumber: 'INV-001',
      date: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 7)),
      client: sampleClient,
      items: [sampleLineItem],
      subtotal: 100.0,
      taxAmount: 5.0,
      discount: 0.0,
      total: 105.0,
      status: InvoiceStatus.draft,
    );

    final sampleProfile = BusinessProfile(
      companyName: 'My Company',
      email: 'me@company.com',
      currency: 'AED',
    );

    final sampleProduct = Product(
      id: 'prod-1',
      name: 'Test Product',
      unitPrice: 50.0,
      stockQuantity: 10,
    );

    final sampleLpo = Lpo(
      id: 'lpo-1',
      lpoNumber: 'LPO-001',
      date: DateTime.now(),
      vendor: sampleClient,
      items: [sampleLineItem],
      subtotal: 100.0,
      taxAmount: 5.0,
      discount: 0.0,
      total: 105.0,
      status: LpoStatus.draft,
    );

    final sampleQuotation = Quotation(
      id: 'qt-1',
      quotationNumber: 'QT-001',
      date: DateTime.now(),
      client: sampleClient,
      items: [sampleLineItem],
      subtotal: 100.0,
      taxAmount: 5.0,
      discount: 0.0,
      total: 105.0,
      status: QuotationStatus.draft,
    );

    final sampleProforma = ProformaInvoice(
      id: 'pf-1',
      proformaNumber: 'PF-001',
      date: DateTime.now(),
      client: sampleClient,
      items: [sampleLineItem],
      subtotal: 100.0,
      taxAmount: 5.0,
      discount: 0.0,
      total: 105.0,
      status: ProformaStatus.draft,
    );

    // 2. Simulate Export (toJson)
    final Map<String, dynamic> exportData = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'invoices': [sampleInvoice.toJson()],
      'settings': [sampleProfile.toJson()],
      'clients': [sampleClient.toJson()],
      'quotations': [sampleQuotation.toJson()],
      'products': [sampleProduct.toJson()],
      'lpos': [sampleLpo.toJson()],
      'proformas': [sampleProforma.toJson()],
    };

    // 3. Simulate JSON Encoding and Decoding
    final String jsonString = jsonEncode(exportData);
    print('Exported JSON: $jsonString');

    final Map<String, dynamic> decodedData = jsonDecode(jsonString);

    // 4. Simulate Import (fromJson)
    // Settings
    if (decodedData['settings'] != null) {
      for (var item in decodedData['settings']) {
        final profile = BusinessProfile.fromJson(item);
        expect(profile.companyName, 'My Company');
      }
    }

    // Invoices
    if (decodedData['invoices'] != null) {
      for (var item in decodedData['invoices']) {
        final invoice = Invoice.fromJson(item);
        expect(invoice.invoiceNumber, 'INV-001');
      }
    }

    // Products
    if (decodedData['products'] != null) {
      for (var item in decodedData['products']) {
        final product = Product.fromJson(item);
        expect(product.name, 'Test Product');
      }
    }

    // LPOs
    if (decodedData['lpos'] != null) {
      for (var item in decodedData['lpos']) {
        final lpo = Lpo.fromJson(item);
        expect(lpo.lpoNumber, 'LPO-001');
      }
    }

    // Quotations
    if (decodedData['quotations'] != null) {
      for (var item in decodedData['quotations']) {
        final quotation = Quotation.fromJson(item);
        expect(quotation.quotationNumber, 'QT-001');
      }
    }

    // Proformas
    if (decodedData['proformas'] != null) {
      for (var item in decodedData['proformas']) {
        final proforma = ProformaInvoice.fromJson(item);
        expect(proforma.proformaNumber, 'PF-001');
      }
    }
  });
}
