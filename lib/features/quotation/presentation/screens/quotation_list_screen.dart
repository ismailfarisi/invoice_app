import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/quotation/data/quotation_repository.dart';
import 'package:flutter_invoice_app/features/quotation/domain/models/quotation.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:flutter_invoice_app/features/quotation/presentation/screens/quotation_form_screen.dart';
import 'package:intl/intl.dart';

class QuotationListScreen extends ConsumerWidget {
  const QuotationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(quotationRepositoryProvider);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quotations'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Draft'),
              Tab(text: 'Sent'),
              Tab(text: 'Accepted'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: ValueListenableBuilder(
          valueListenable: repo.listenable,
          builder: (context, box, _) {
            final quotations = box.values.toList();
            return TabBarView(
              children: [
                _QuotationList(quotations: quotations),
                _QuotationList(
                  emptyHint: 'Quotations you are still preparing show here.',
                  quotations: quotations
                      .where((q) => q.status == QuotationStatus.draft)
                      .toList(),
                ),
                _QuotationList(
                  emptyHint:
                      'Quotations waiting for a customer reply show here.',
                  quotations: quotations
                      .where((q) => q.status == QuotationStatus.sent)
                      .toList(),
                ),
                _QuotationList(
                  emptyHint:
                      'Accepted quotations show here. Open one to turn it into an invoice.',
                  quotations: quotations
                      .where((q) => q.status == QuotationStatus.accepted)
                      .toList(),
                ),
                _QuotationList(
                  emptyHint: 'Rejected and expired quotations show here.',
                  quotations: quotations
                      .where(
                        (q) =>
                            q.status == QuotationStatus.rejected ||
                            q.status == QuotationStatus.expired,
                      )
                      .toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuotationList extends StatelessWidget {
  final List<Quotation> quotations;
  final String emptyHint;
  const _QuotationList({
    required this.quotations,
    this.emptyHint = 'Tap New Quotation to create your first one.',
  });

  @override
  Widget build(BuildContext context) {
    if (quotations.isEmpty) {
      final scheme = Theme.of(context).colorScheme;
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.request_quote_outlined,
                size: 64,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No quotations here yet',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  emptyHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: quotations.length,
      itemBuilder: (context, index) {
        final quotation = quotations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _QuotationCard(quotation: quotation),
        );
      },
    );
  }
}

class _QuotationCard extends StatelessWidget {
  final Quotation quotation;

  const _QuotationCard({required this.quotation});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(24);
    final clientName = quotation.client.name;
    return Container(
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
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuotationFormScreen(quotation: quotation),
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
                    color: scheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.request_quote_outlined,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName.isEmpty ? 'No client name' : clientName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${quotation.quotationNumber} • ${quotation.date != null ? DateFormat.yMMMd().format(quotation.date!) : 'No Date'}',
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
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          CurrencyFormatter.format(
                            quotation.total,
                            symbol: quotation.currency ?? 'AED',
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _StatusBadge(status: quotation.status),
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
  final QuotationStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final base = _getStatusColor(status);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = dark ? Color.lerp(base, Colors.white, 0.6)! : base;
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

  Color _getStatusColor(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.draft:
        return Colors.grey.shade700;
      case QuotationStatus.sent:
        return Colors.blue.shade800;
      case QuotationStatus.accepted:
        return Colors.green.shade800;
      case QuotationStatus.rejected:
        return Colors.red.shade800;
      case QuotationStatus.expired:
        return Colors.orange.shade900;
    }
  }
}
