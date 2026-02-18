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
        error: (err, stack) => Center(child: Text('Error: $err')),
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
    if (proformas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_outlined, // Different icon
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No proforma invoices found',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
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
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProformaFormScreen(proforma: proforma),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ??
              Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.tertiary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.assignment_outlined,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proforma.client.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${proforma.proformaNumber} • ${proforma.date != null ? DateFormat.yMMMd().format(proforma.date!) : 'No Date'}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(proforma.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                _StatusBadge(status: proforma.status),
              ],
            ),
          ],
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
    Color color;
    switch (status) {
      case ProformaStatus.draft:
        color = Colors.grey;
        break;
      case ProformaStatus.sent:
        color = Colors.blue;
        break;
      case ProformaStatus.accepted:
        color = Colors.green;
        break;
      case ProformaStatus.rejected:
        color = Colors.red;
        break;
      case ProformaStatus.converted:
        color = Colors.purple;
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
