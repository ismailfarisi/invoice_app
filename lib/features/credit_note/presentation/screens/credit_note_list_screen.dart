import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:flutter_invoice_app/features/credit_note/data/credit_note_repository.dart';
import 'package:flutter_invoice_app/features/credit_note/domain/credit_note_rules.dart';
import 'package:flutter_invoice_app/features/credit_note/domain/models/credit_note.dart';
import 'package:flutter_invoice_app/features/credit_note/presentation/screens/credit_note_form_screen.dart';
import 'package:flutter_invoice_app/features/credit_note/presentation/screens/credit_note_preview_screen.dart';
import 'package:flutter_invoice_app/features/invoice/data/invoice_repository.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:intl/intl.dart';

class CreditNoteListScreen extends ConsumerWidget {
  const CreditNoteListScreen({super.key});

  Future<void> _startNew(BuildContext context, WidgetRef ref) async {
    final notes = ref.read(creditNoteRepositoryProvider).getAll();
    final invoices =
        ref
            .read(invoiceRepositoryProvider)
            .getAllInvoices()
            .where(
              (i) =>
                  CreditNoteRules.canCredit(i) &&
                  CreditNoteRules.creditableLines(i, notes).isNotEmpty,
            )
            .toList()
          ..sort(
            (a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)),
          );

    if (invoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('There are no sent or paid invoices left to credit.'),
        ),
      );
      return;
    }

    final picked = await showModalBottomSheet<Invoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _InvoicePickerSheet(invoices: invoices),
    );
    if (picked != null && context.mounted) {
      openCreditNoteForm(context, ref, picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(creditNoteRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Credit Notes')),
      body: ValueListenableBuilder(
        valueListenable: repository.listenable,
        builder: (context, box, _) {
          final notes = box.values.toList()
            ..sort((a, b) {
              final byDate = b.date.compareTo(a.date);
              if (byDate != 0) return byDate;
              return b.creditNoteNumber.compareTo(a.creditNoteNumber);
            });
          if (notes.isEmpty) return const _EmptyState();
          return ListView.builder(
            // Bottom space keeps the last card clear of the floating button.
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
            itemCount: notes.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _CreditNoteCard(note: notes[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNew(context, ref),
        label: const Text(
          'New Credit Note',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_return_outlined,
              size: 64,
              color: colors.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No credit notes yet',
              style: TextStyle(color: colors.onSurface, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Issue one when a customer cancels or returns all or part of an invoice. Tap New Credit Note to start.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditNoteCard extends StatelessWidget {
  final CreditNote note;

  const _CreditNoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(24);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreditNotePreviewScreen(note: note),
            ),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? colors.surface,
            borderRadius: radius,
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.2),
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
                  color: colors.tertiary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.assignment_return_outlined,
                  color: colors.tertiary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.client.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${note.creditNoteNumber} • ${DateFormat.yMMMd().format(note.date).replaceAll(' ', ' ')}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Against ${note.invoiceNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(note.total, symbol: note.currency),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: note.isVoided ? colors.onSurfaceVariant : null,
                      decoration: note.isVoided
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StatusBadge(isVoided: note.isVoided),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isVoided;

  const _StatusBadge({required this.isVoided});

  @override
  Widget build(BuildContext context) {
    // Deep shades on a light tint, pale shades on a dark one, so the label
    // keeps its contrast in both themes.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = isVoided
        ? (dark ? Colors.grey.shade300 : Colors.grey.shade800)
        : (dark ? Colors.green.shade200 : Colors.green.shade900);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isVoided ? 'VOID' : 'ISSUED',
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

class _InvoicePickerSheet extends StatefulWidget {
  final List<Invoice> invoices;

  const _InvoicePickerSheet({required this.invoices});

  @override
  State<_InvoicePickerSheet> createState() => _InvoicePickerSheetState();
}

class _InvoicePickerSheetState extends State<_InvoicePickerSheet> {
  String _query = '';

  List<Invoice> get _matches {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.invoices;
    return widget.invoices
        .where(
          (i) =>
              i.invoiceNumber.toLowerCase().contains(query) ||
              i.client.name.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    final height = MediaQuery.of(context).size.height * 0.75;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Text(
                  'Which invoice is this for?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search by customer or invoice number',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: matches.isEmpty
                    ? Center(
                        child: Text(
                          'No matching invoices',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final invoice = matches[index];
                          final date = invoice.date;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                            ),
                            title: Text(
                              invoice.client.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              date != null
                                  ? '${invoice.invoiceNumber} • ${DateFormat.yMMMd().format(date)}'
                                  : invoice.invoiceNumber,
                            ),
                            trailing: Text(
                              CurrencyFormatter.format(
                                invoice.total,
                                symbol: invoice.currency ?? 'AED',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () => Navigator.of(context).pop(invoice),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
