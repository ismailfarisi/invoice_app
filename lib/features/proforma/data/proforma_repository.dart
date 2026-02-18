import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_invoice_app/features/proforma/domain/models/proforma.dart';

final proformaRepositoryProvider = Provider((ref) => ProformaRepository());

class ProformaRepository {
  static const String boxName = 'proformas';

  Future<ValueListenable<Box<ProformaInvoice>>> getListenable() async {
    final box = await _getBox();
    return box.listenable();
  }

  Future<Box<ProformaInvoice>> _getBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<ProformaInvoice>(boxName);
    }
    return await Hive.openBox<ProformaInvoice>(boxName);
  }

  List<ProformaInvoice> getAllProformas() {
    if (!Hive.isBoxOpen(boxName)) return [];
    final box = Hive.box<ProformaInvoice>(boxName);
    return box.values.toList();
  }

  Future<List<ProformaInvoice>> getProformas() async {
    final box = await _getBox();
    return box.values.toList();
  }

  Future<void> saveProforma(ProformaInvoice proforma) async {
    final box = await _getBox();
    await box.put(proforma.id, proforma);
  }

  Future<void> deleteProforma(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
