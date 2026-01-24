import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_invoice_app/features/lpo/domain/models/lpo.dart';

class LpoRepository {
  static const String boxName = 'lpos';

  Future<Box<Lpo>> _getBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<Lpo>(boxName);
    }
    return await Hive.openBox<Lpo>(boxName);
  }

  Future<List<Lpo>> getLpos() async {
    final box = await _getBox();
    return box.values.toList(); // Return all LPOs
  }

  Future<void> saveLpo(Lpo lpo) async {
    final box = await _getBox();
    await box.put(lpo.id, lpo);
  }

  Future<void> deleteLpo(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<Lpo?> getLpo(String id) async {
    final box = await _getBox();
    return box.get(id);
  }
}
