import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/lpo/presentation/providers/lpo_provider.dart';
import 'package:flutter_invoice_app/features/lpo/domain/models/lpo.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:flutter_invoice_app/features/lpo/presentation/screens/lpo_form_screen.dart';
import 'package:intl/intl.dart';

class LpoListScreen extends ConsumerWidget {
  const LpoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lposAsyncValue = ref.watch(lpoListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Orders')),
      body: lposAsyncValue.when(
        data: (lpos) => _LpoList(lpos: lpos),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Couldn't load your purchase orders.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(lpoListProvider.notifier).loadLpos(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LpoFormScreen()));
        },
        label: const Text(
          'New Order',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _LpoList extends StatelessWidget {
  final List<Lpo> lpos;
  const _LpoList({required this.lpos});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (lpos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: scheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No purchase orders yet',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Order goods or services from a supplier. Tap New Order to create your first LPO.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      // Bottom padding keeps the last card clear of the floating button.
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      itemCount: lpos.length,
      itemBuilder: (context, index) {
        final lpo = lpos[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _LpoCard(lpo: lpo),
        );
      },
    );
  }
}

class _LpoCard extends StatelessWidget {
  final Lpo lpo;

  const _LpoCard({required this.lpo});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(24);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Theme.of(context).cardTheme.color ?? scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => LpoFormScreen(lpo: lpo)));
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.secondary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lpo.vendor.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${lpo.lpoNumber} • ${lpo.date != null ? DateFormat.yMMMd().format(lpo.date!) : 'No date'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          CurrencyFormatter.format(
                            lpo.total,
                            symbol: lpo.currency ?? 'AED',
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _StatusBadge(status: lpo.status),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final LpoStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Darker shades (light mode) / lighter shades (dark mode) so the label
    // stays readable on its own 10% tint.
    final Color color;
    switch (status) {
      case LpoStatus.draft:
        color = scheme.onSurfaceVariant;
        break;
      case LpoStatus.sent:
        color = dark ? Colors.blue.shade200 : Colors.blue.shade800;
        break;
      case LpoStatus.approved:
        color = dark ? Colors.green.shade200 : Colors.green.shade800;
        break;
      case LpoStatus.rejected:
        color = dark ? Colors.red.shade200 : Colors.red.shade800;
        break;
      case LpoStatus.completed:
        color = dark ? Colors.teal.shade200 : Colors.teal.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
