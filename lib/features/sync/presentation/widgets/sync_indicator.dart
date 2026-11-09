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
        padding: EdgeInsets.all(14.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            semanticsLabel: 'Syncing',
          ),
        ),
      ),
      error: (e, st) => IconButton(
        tooltip: 'Sync failed. Your documents are saved on this phone.',
        icon: Icon(Icons.error, color: Theme.of(context).colorScheme.error),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Sync failed. Your documents are still saved on this phone.',
              ),
            ),
          );
        },
      ),
    );
  }
}
