import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/invoice/data/invoice_repository.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_invoice_app/features/invoice/presentation/screens/generic_pdf_preview_screen.dart';
import 'package:flutter_invoice_app/core/services/pdf/pdf_service.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart';

class DeliveryNoteListScreen extends ConsumerWidget {
  const DeliveryNoteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(invoiceRepositoryProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Delivery Notes'),
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
            // Sort by date descending
            invoices.sort(
              (a, b) =>
                  (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)),
            );

            return TabBarView(
              children: [
                _DeliveryNoteList(invoices: invoices),
                _DeliveryNoteList(
                  invoices: invoices
                      .where((i) => i.status == InvoiceStatus.paid)
                      .toList(),
                ),
                _DeliveryNoteList(
                  invoices: invoices
                      .where((i) => i.status != InvoiceStatus.paid)
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

class _DeliveryNoteList extends StatelessWidget {
  final List<Invoice> invoices;
  const _DeliveryNoteList({required this.invoices});

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No invoices found',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
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
          child: _DeliveryNoteCard(invoice: invoice),
        );
      },
    );
  }
}

class _DeliveryNoteCard extends ConsumerWidget {
  final Invoice invoice;

  const _DeliveryNoteCard({required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        final profile = ref
            .read(businessProfileRepositoryProvider)
            .getProfile();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GenericPdfPreviewScreen(
              title: 'Delivery Note Preview',
              pdfFileName: 'DeliveryNote_${invoice.invoiceNumber}.pdf',
              buildEvent: (format) =>
                  PdfService().generateDeliveryNote(invoice, profile: profile),
            ),
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
                Icons.local_shipping_outlined,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.client.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${invoice.invoiceNumber} • ${invoice.date != null ? DateFormat.yMMMd().format(invoice.date!) : 'No Date'}',
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
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
