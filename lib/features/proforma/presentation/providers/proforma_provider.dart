import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/proforma/data/proforma_repository.dart';
import 'package:flutter_invoice_app/features/proforma/domain/models/proforma.dart';

final proformaRepositoryProvider = Provider<ProformaRepository>((ref) {
  return ProformaRepository();
});

final proformaListProvider =
    StateNotifierProvider<
      ProformaListNotifier,
      AsyncValue<List<ProformaInvoice>>
    >((ref) {
      final repository = ref.watch(proformaRepositoryProvider);
      return ProformaListNotifier(repository);
    });

class ProformaListNotifier
    extends StateNotifier<AsyncValue<List<ProformaInvoice>>> {
  final ProformaRepository _repository;

  ProformaListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProformas();
  }

  Future<void> loadProformas() async {
    try {
      final proformas = await _repository.getProformas();
      proformas.sort(
        (a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)),
      );
      state = AsyncValue.data(proformas);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveProforma(ProformaInvoice proforma) async {
    try {
      await _repository.saveProforma(proforma);
      await loadProformas();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProforma(String id) async {
    try {
      await _repository.deleteProforma(id);
      await loadProformas();
    } catch (e) {
      rethrow;
    }
  }
}
