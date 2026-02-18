import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/lpo/data/lpo_repository.dart';
import 'package:flutter_invoice_app/features/lpo/domain/models/lpo.dart';

final lpoRepositoryProvider = Provider<LpoRepository>((ref) {
  return LpoRepository();
});

final lpoListProvider =
    StateNotifierProvider<LpoListNotifier, AsyncValue<List<Lpo>>>((ref) {
      final repository = ref.watch(lpoRepositoryProvider);
      return LpoListNotifier(repository);
    });

class LpoListNotifier extends StateNotifier<AsyncValue<List<Lpo>>> {
  final LpoRepository _repository;

  LpoListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadLpos();
  }

  Future<void> loadLpos() async {
    try {
      final lpos = await _repository.getLpos();
      // Sort by date descending by default
      lpos.sort(
        (a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)),
      );
      state = AsyncValue.data(lpos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveLpo(Lpo lpo) async {
    try {
      await _repository.saveLpo(lpo);
      await loadLpos();
    } catch (e) {
      // Handle error (maybe rethrow or update state with error if specific handling needed)
      rethrow;
    }
  }

  Future<void> deleteLpo(String id) async {
    try {
      await _repository.deleteLpo(id);
      await loadLpos();
    } catch (e) {
      rethrow;
    }
  }
}
