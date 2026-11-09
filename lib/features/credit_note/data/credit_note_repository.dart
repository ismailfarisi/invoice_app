import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_invoice_app/features/credit_note/domain/credit_note_rules.dart';
import 'package:flutter_invoice_app/features/credit_note/domain/models/credit_note.dart';

final creditNoteRepositoryProvider = Provider((ref) => CreditNoteRepository());

class CreditNoteRepository {
  final Box<CreditNote> _box = Hive.box<CreditNote>('credit_notes');

  List<CreditNote> getAll() => _box.values.toList();

  ValueListenable<Box<CreditNote>> get listenable => _box.listenable();

  String nextNumber() => CreditNoteRules.nextNumber(_box.values);

  Future<void> save(CreditNote note) async {
    await _box.put(note.id, note);
  }

  Future<void> voidNote(CreditNote note) async {
    await _box.put(
      note.id,
      note.copyWith(
        isVoided: true,
        isSynced: false,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
