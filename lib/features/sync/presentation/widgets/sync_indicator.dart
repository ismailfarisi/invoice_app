import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/sync/presentation/providers/sync_provider.dart';

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    return syncState.when(
      data: (_) => const SizedBox.shrink(),
      loading: () => const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, st) => IconButton(
        icon: const Icon(Icons.error, color: Colors.red),
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Sync Failed: $e')));
        },
      ),
    );
  }
}
