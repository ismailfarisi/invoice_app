import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/sync/data/sync_repository.dart';

final syncProvider =
    StateNotifierProvider<SyncNotifier, AsyncValue<SyncStats?>>((ref) {
      final repository = ref.read(syncRepositoryProvider);
      return SyncNotifier(repository);
    });

class SyncNotifier extends StateNotifier<AsyncValue<SyncStats?>> {
  final SyncRepository _repository;

  SyncNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> sync() async {
    state = const AsyncValue.loading();
    try {
      final stats = await _repository.syncAll();
      if (stats.error != null) {
        state = AsyncValue.error(stats.error!, StackTrace.current);
      } else {
        state = AsyncValue.data(stats);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resetSync() async {
    await _repository.resetSyncStatus();
    state = const AsyncValue.data(null);
  }
}
