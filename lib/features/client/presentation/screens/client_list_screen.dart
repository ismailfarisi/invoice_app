import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_invoice_app/core/services/excel/excel_service.dart';
import 'package:flutter_invoice_app/core/services/pdf/pdf_service.dart';
import 'package:flutter_invoice_app/core/utils/file_utils.dart';
import 'package:flutter_invoice_app/features/client/domain/models/customer_statement.dart';
import 'package:flutter_invoice_app/features/client/presentation/screens/client_form_screen.dart';
import 'package:flutter_invoice_app/features/invoice/data/invoice_repository.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/invoice/presentation/screens/generic_pdf_preview_screen.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart';

class ClientListScreen extends ConsumerWidget {
  const ClientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBar(
        title: const Text(
          'Companies',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Client>('clients').listenable(),
        builder: (context, Box<Client> box, _) {
          if (box.values.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No companies yet',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            );
          }
          final clients = box.values.toList();
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ClientCard(
                  client: client,
                  onDelete: () => box.delete(client.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClientFormScreen()),
          );
        },
        label: const Text(
          'Add Company',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _ClientCard extends ConsumerWidget {
  final Client client;
  final VoidCallback onDelete;

  const _ClientCard({required this.client, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClientFormScreen(client: client)),
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
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.business,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    client.contactPerson ?? client.email,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.receipt_long_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'Statement of Account',
              onPressed: () => _showStatementOptions(context, ref, client),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Company'),
                    content: const Text(
                      'Are you sure you want to delete this company?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          onDelete();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

void _showStatementOptions(BuildContext context, WidgetRef ref, Client client) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (modalContext) {
      return _StatementOptionsBottomSheet(
        client: client,
        onGenerate: (fromDate, toDate) {
          Navigator.pop(modalContext);
          _generateAndNavigateToStatement(
            context,
            ref,
            client,
            fromDate,
            toDate,
          );
        },
      );
    },
  );
}

void _generateAndNavigateToStatement(
  BuildContext context,
  WidgetRef ref,
  Client client,
  DateTime? fromDate,
  DateTime? toDate,
) {
  final allInvoices = ref.read(invoiceRepositoryProvider).getAllInvoices();
  final profile = ref.read(settingsRepositoryProvider).getBusinessProfile();
  final statement = CustomerStatement.fromInvoices(
    client: client,
    allInvoices: allInvoices,
    fromDate: fromDate,
    toDate: toDate,
  );

  final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
  final sanitizedClientName = client.name.replaceAll(RegExp(r'[^\w\.-]'), '_');

  if (!context.mounted) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => GenericPdfPreviewScreen(
        title: 'Statement - ${client.name}',
        pdfFileName: 'Statement_${sanitizedClientName}_$dateStr.pdf',
        buildEvent: (format) => PdfService().generateCustomerStatement(
          statement,
          profile: profile,
        ),
        onExportExcel: () async {
          try {
            final bytes = await ExcelService().generateCustomerStatement(
              statement,
              profile: profile,
            );
            if (bytes != null) {
              await FileUtils.shareFile(
                bytes,
                'Statement_${sanitizedClientName}_$dateStr.xlsx',
              );
            }
          } catch (e) {
            debugPrint('Failed to export statement to Excel: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to export statement to Excel.'),
                ),
              );
            }
          }
        },
      ),
    ),
  );
}

enum _StatementDateFilter { allTime, thisMonth, thisYear, customRange }

class _StatementOptionsBottomSheet extends StatefulWidget {
  final Client client;
  final void Function(DateTime? fromDate, DateTime? toDate) onGenerate;

  const _StatementOptionsBottomSheet({
    required this.client,
    required this.onGenerate,
  });

  @override
  State<_StatementOptionsBottomSheet> createState() =>
      _StatementOptionsBottomSheetState();
}

class _StatementOptionsBottomSheetState
    extends State<_StatementOptionsBottomSheet> {
  _StatementDateFilter _selectedFilter = _StatementDateFilter.allTime;
  DateTimeRange? _customDateRange;

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _customDateRange,
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedFilter = _StatementDateFilter.customRange;
        _customDateRange = picked;
      });
    }
  }

  void _onFilterSelected(_StatementDateFilter filter) {
    if (filter == _StatementDateFilter.customRange) {
      _pickCustomRange();
    } else {
      setState(() {
        _selectedFilter = filter;
      });
    }
  }

  Future<void> _onGeneratePressed() async {
    DateTime? fromDate;
    DateTime? toDate;

    final now = DateTime.now();
    switch (_selectedFilter) {
      case _StatementDateFilter.allTime:
        fromDate = null;
        toDate = null;
        break;
      case _StatementDateFilter.thisMonth:
        fromDate = DateTime(now.year, now.month, 1);
        toDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case _StatementDateFilter.thisYear:
        fromDate = DateTime(now.year, 1, 1);
        toDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case _StatementDateFilter.customRange:
        if (_customDateRange == null) {
          await _pickCustomRange();
          if (!mounted || _customDateRange == null) return;
        }
        fromDate = _customDateRange!.start;
        toDate = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
        );
        break;
    }

    widget.onGenerate(fromDate, toDate);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Customer Statement - ${widget.client.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All Time'),
                  selected: _selectedFilter == _StatementDateFilter.allTime,
                  onSelected: (_) =>
                      _onFilterSelected(_StatementDateFilter.allTime),
                ),
                ChoiceChip(
                  label: const Text('This Month'),
                  selected: _selectedFilter == _StatementDateFilter.thisMonth,
                  onSelected: (_) =>
                      _onFilterSelected(_StatementDateFilter.thisMonth),
                ),
                ChoiceChip(
                  label: const Text('This Year'),
                  selected: _selectedFilter == _StatementDateFilter.thisYear,
                  onSelected: (_) =>
                      _onFilterSelected(_StatementDateFilter.thisYear),
                ),
                ChoiceChip(
                  label: const Text('Custom Range'),
                  selected: _selectedFilter == _StatementDateFilter.customRange,
                  onSelected: (_) =>
                      _onFilterSelected(_StatementDateFilter.customRange),
                ),
              ],
            ),
            if (_selectedFilter == _StatementDateFilter.customRange &&
                _customDateRange != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickCustomRange,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${dateFormat.format(_customDateRange!.start)} - ${dateFormat.format(_customDateRange!.end)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _onGeneratePressed,
              icon: const Icon(Icons.receipt_long),
              label: const Text('View Statement'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
