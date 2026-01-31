import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';

final invoiceRepositoryProvider = Provider((ref) => InvoiceRepository());

class InvoiceRepository {
  final Box<Invoice> _box = Hive.box<Invoice>('invoices');

  List<Invoice> getAllInvoices() {
    return _box.values.toList();
  }

  ValueListenable<Box<Invoice>> get listenable => _box.listenable();

  Invoice? getInvoice(String id) {
    return _box.get(id);
  }

  Future<void> saveInvoice(Invoice invoice) async {
    await _box.put(invoice.id, invoice);
  }

  Future<void> deleteInvoice(String id) async {
    await _box.delete(id);
  }
}
