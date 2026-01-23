import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_invoice_app/features/quotation/domain/models/quotation.dart';

final quotationRepositoryProvider = Provider((ref) => QuotationRepository());

class QuotationRepository {
  final Box<Quotation> _box = Hive.box<Quotation>('quotations');

  List<Quotation> getAllQuotations() {
    return _box.values.toList();
  }

  Quotation? getQuotation(String id) {
    return _box.get(id);
  }

  Future<void> saveQuotation(Quotation quotation) async {
    await _box.put(quotation.id, quotation);
  }

  Future<void> deleteQuotation(String id) async {
    await _box.delete(id);
  }
}
