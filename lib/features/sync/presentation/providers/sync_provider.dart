import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/sync/data/sync_repository.dart';

final syncProvider = StateNotifierProvider<SyncNotifier, AsyncValue<void>>((
  ref,
) {
  final repository = ref.read(syncRepositoryProvider);
  return SyncNotifier(repository);
});

class SyncNotifier extends StateNotifier<AsyncValue<void>> {
  final SyncRepository _repository;

  SyncNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> sync() async {
    state = const AsyncValue.loading();
    try {
      await _repository.syncAll();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
