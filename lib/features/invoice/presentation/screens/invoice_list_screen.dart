import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/credit_note/data/credit_note_repository.dart';
import 'package:flutter_invoice_app/features/credit_note/domain/credit_note_rules.dart';
import 'package:flutter_invoice_app/features/invoice/data/invoice_repository.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:flutter_invoice_app/features/invoice/presentation/screens/invoice_form_screen.dart';
import 'package:intl/intl.dart';

class InvoiceListScreen extends ConsumerWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(invoiceRepositoryProvider);
    final creditRepo = ref.watch(creditNoteRepositoryProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Invoices'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Paid'),
              Tab(text: 'Pending'),
            ],
          ),
        ),
        body: ValueListenableBuilder(
          valueListenable: repo.listenable,
          builder: (context, box, _) {
            final invoices = box.values.toList();
            return ValueListenableBuilder(
              valueListenable: creditRepo.listenable,
              builder: (context, creditBox, _) {
                final credited = CreditNoteRules.creditedByInvoice(
                  creditBox.values,
                );
                return TabBarView(
                  children: [
                    _InvoiceList(
                      invoices: invoices,
                      credited: credited,
                      emptyHint:
                          'Invoices you create will appear here.',
                    ),
                    _InvoiceList(
                      invoices: invoices
                          .where((i) => i.status == InvoiceStatus.paid)
                          .toList(),
                      credited: credited,
                      emptyHint:
                          'Invoices you mark as paid will show up here.',
                    ),
                    _InvoiceList(
                      invoices: invoices
                          .where(
                            (i) =>
                                i.status != InvoiceStatus.paid &&
                                i.status != InvoiceStatus.cancelled,
                          )
                          .toList(),
                      credited: credited,
                      emptyHint: 'Nothing is waiting to be paid.',
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _InvoiceList extends StatelessWidget {
  final List<Invoice> invoices;
  final Map<String, double> credited;
  final String? emptyHint;
  const _InvoiceList({
    required this.invoices,
    required this.credited,
    this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      final scheme = Theme.of(context).colorScheme;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: scheme.outlineVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No invoices here yet',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (emptyHint != null) ...[
                const SizedBox(height: 8),
                Text(
                  emptyHint!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _InvoiceCard(
            invoice: invoice,
            creditedAmount: credited[invoice.id] ?? 0,
          ),
        );
      },
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final double creditedAmount;

  const _InvoiceCard({required this.invoice, required this.creditedAmount});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(24);
    final symbol = invoice.currency ?? 'AED';
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
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InvoiceFormScreen(invoice: invoice),
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
                    Icons.description_outlined,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.client.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${invoice.invoiceNumber} • ${invoice.date != null ? DateFormat.yMMMd().format(invoice.date!).replaceAll(' ', '\u00A0') : 'No Date'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      if (creditedAmount > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Credited ${CurrencyFormatter.format(creditedAmount, symbol: symbol)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.tertiary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          CurrencyFormatter.format(
                            invoice.total,
                            symbol: symbol,
                          ),
                          maxLines: 1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _StatusBadge(status: invoice.status),
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
  final InvoiceStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final Color color;
    switch (status) {
      case InvoiceStatus.paid:
        color = dark ? Colors.green.shade300 : Colors.green.shade800;
        break;
      case InvoiceStatus.overdue:
        color = dark ? Colors.red.shade300 : Colors.red.shade800;
        break;
      case InvoiceStatus.cancelled:
        color = Theme.of(context).colorScheme.onSurfaceVariant;
        break;
      case InvoiceStatus.draft:
      case InvoiceStatus.sent:
        color = dark ? Colors.orange.shade300 : Colors.orange.shade900;
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
