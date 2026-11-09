import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/proforma/presentation/providers/proforma_provider.dart';
import 'package:flutter_invoice_app/features/proforma/domain/models/proforma.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:flutter_invoice_app/features/proforma/presentation/screens/proforma_form_screen.dart';
import 'package:intl/intl.dart';

class ProformaListScreen extends ConsumerWidget {
  const ProformaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proformaAsyncValue = ref.watch(proformaListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Proforma Invoices')),
      body: proformaAsyncValue.when(
        data: (proformas) => _ProformaList(proformas: proformas),
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
                  "Couldn't load your proforma invoices.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(proformaListProvider.notifier).loadProformas(),
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
          ).push(MaterialPageRoute(builder: (_) => const ProformaFormScreen()));
        },
        label: const Text(
          'New Proforma',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _ProformaList extends StatelessWidget {
  final List<ProformaInvoice> proformas;
  const _ProformaList({required this.proformas});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (proformas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_outlined,
                size: 64,
                color: scheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No proforma invoices yet',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Send a customer an advance quote for payment. Tap New Proforma to create your first one.',
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
      itemCount: proformas.length,
      itemBuilder: (context, index) {
        final proforma = proformas[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ProformaCard(proforma: proforma),
        );
      },
    );
  }
}

class _ProformaCard extends StatelessWidget {
  final ProformaInvoice proforma;

  const _ProformaCard({required this.proforma});

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
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProformaFormScreen(proforma: proforma),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.tertiary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.assignment_outlined,
                    color: scheme.tertiary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proforma.client.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${proforma.proformaNumber} • ${proforma.date != null ? DateFormat.yMMMd().format(proforma.date!) : 'No date'}',
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
                            proforma.total,
                            symbol: proforma.currency ?? 'AED',
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _StatusBadge(status: proforma.status),
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
  final ProformaStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Darker shades (light mode) / lighter shades (dark mode) so the label
    // stays readable on its own 10% tint.
    final Color color;
    switch (status) {
      case ProformaStatus.draft:
        color = scheme.onSurfaceVariant;
        break;
      case ProformaStatus.sent:
        color = dark ? Colors.blue.shade200 : Colors.blue.shade800;
        break;
      case ProformaStatus.accepted:
        color = dark ? Colors.green.shade200 : Colors.green.shade800;
        break;
      case ProformaStatus.rejected:
        color = dark ? Colors.red.shade200 : Colors.red.shade800;
        break;
      case ProformaStatus.converted:
        color = dark ? Colors.purple.shade200 : Colors.purple.shade800;
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
