import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_invoice_app/features/invoice/data/invoice_repository.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:flutter_invoice_app/features/quotation/domain/models/quotation.dart';
import 'package:flutter_invoice_app/features/quotation/data/quotation_repository.dart';
import 'package:flutter_invoice_app/features/proforma/domain/models/proforma.dart';
import 'package:flutter_invoice_app/features/proforma/data/proforma_repository.dart';
import 'package:intl/intl.dart';

class DashboardOverview extends ConsumerWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(invoiceRepositoryProvider).getAllInvoices();
    final quotations = ref
        .watch(quotationRepositoryProvider)
        .getAllQuotations();
    final proformas = ref.watch(proformaRepositoryProvider).getAllProformas();

    // Financial Metrics
    final totalRevenue = invoices
        .where((i) => i.status == InvoiceStatus.paid)
        .fold(0.0, (sum, i) => sum + i.total);

    final pendingAmount = invoices
        .where(
          (i) =>
              i.status != InvoiceStatus.paid &&
              i.status != InvoiceStatus.cancelled,
        )
        .fold(0.0, (sum, i) => sum + i.total);

    final totalBilled = invoices
        .where((i) => i.status != InvoiceStatus.cancelled)
        .fold(0.0, (sum, i) => sum + i.total);

    final collectionRate = totalBilled > 0
        ? (totalRevenue / totalBilled) * 100
        : 0.0;

    final avgInvoiceValue = invoices.isNotEmpty
        ? totalBilled / invoices.length
        : 0.0;

    // Pipeline Data
    final activeQuotesValue = quotations
        .where(
          (q) =>
              q.status == QuotationStatus.sent ||
              q.status == QuotationStatus.draft,
        )
        .fold(0.0, (sum, q) => sum + q.total);

    final pendingProformasValue = proformas
        .where(
          (p) =>
              p.status != ProformaStatus.converted &&
              p.status != ProformaStatus.rejected,
        )
        .fold(0.0, (sum, p) => sum + p.total);

    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBar(
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Pipeline Section
                const Text(
                  'Sales Pipeline',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _PipelineFunnel(
                  quotesValue: activeQuotesValue,
                  proformasValue: pendingProformasValue,
                  invoicedValue: totalBilled,
                ),
                const SizedBox(height: 32),

                // Stat Cards Grid
                const Text(
                  'Financial Overview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: constraints.maxWidth > 600 ? 1.5 : 0.95,
                      children: [
                        _StatCard(
                          title: 'Revenue (Paid)',
                          value: CurrencyFormatter.format(totalRevenue),
                          icon: Icons.payments_outlined,
                          color: Colors.green,
                        ),
                        _StatCard(
                          title: 'Outstanding',
                          value: CurrencyFormatter.format(pendingAmount),
                          icon: Icons.pending_actions_outlined,
                          color: Colors.orange,
                        ),
                        _StatCard(
                          title: 'Collection Rate',
                          value: '${collectionRate.toStringAsFixed(1)}%',
                          icon: Icons.analytics_outlined,
                          color: Colors.blue,
                        ),
                        _StatCard(
                          title: 'Avg. Invoice',
                          value: CurrencyFormatter.format(avgInvoiceValue),
                          icon: Icons.receipt_long_outlined,
                          color: Colors.purple,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Revenue Trend',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _RevenueChart(invoices: invoices),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                const Text(
                  'Invoice Status Breakdown',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _StatusBreakdownChart(invoices: invoices),

                const SizedBox(height: 32),
                const Text(
                  'Top Clients',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _TopClientsList(invoices: invoices),

                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Invoices',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to all invoices
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final invoice = invoices.reversed.toList()[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RecentInvoiceTile(invoice: invoice),
                );
              }, childCount: invoices.length > 5 ? 5 : invoices.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentInvoiceTile extends StatelessWidget {
  final Invoice invoice;

  const _RecentInvoiceTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
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
                    fontSize: 16,
                  ),
                ),
                Text(
                  invoice.invoiceNumber,
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
                CurrencyFormatter.format(invoice.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      (invoice.status == InvoiceStatus.paid
                              ? Colors.green
                              : Colors.orange)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  invoice.status.name.toUpperCase(),
                  style: TextStyle(
                    color: invoice.status == InvoiceStatus.paid
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<Invoice> invoices;
  const _RevenueChart({required this.invoices});

  @override
  Widget build(BuildContext context) {
    // Generate actual data from invoices
    final last7Days = List.generate(7, (index) {
      return DateTime.now().subtract(Duration(days: 6 - index));
    });

    final spots = last7Days.asMap().entries.map((entry) {
      final date = entry.value;
      final dailyTotal = invoices
          .where(
            (i) =>
                i.date != null &&
                i.date!.year == date.year &&
                i.date!.month == date.month &&
                i.date!.day == date.day,
          )
          .fold(0.0, (sum, i) => sum + i.total);

      return FlSpot(entry.key.toDouble(), dailyTotal / 1000); // Scale to 'k'
    }).toList();

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(16, 32, 24, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < 7) {
                    final date = last7Days[value.toInt()];
                    return Text(
                      DateFormat('E').format(date).substring(0, 1),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 12,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}k',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PipelineFunnel extends StatelessWidget {
  final double quotesValue;
  final double proformasValue;
  final double invoicedValue;

  const _PipelineFunnel({
    required this.quotesValue,
    required this.proformasValue,
    required this.invoicedValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _FunnelStep(
            label: 'Quotations',
            value: quotesValue,
            color: Colors.blue.shade300,
            percent: 1.0,
          ),
          const SizedBox(height: 8),
          _FunnelStep(
            label: 'Proformas',
            value: proformasValue,
            color: Colors.indigo.shade400,
            percent: (quotesValue + proformasValue) > 0
                ? (proformasValue / (quotesValue + proformasValue)).clamp(
                    0.6,
                    1.0,
                  )
                : 0.8,
          ),
          const SizedBox(height: 8),
          _FunnelStep(
            label: 'Invoiced',
            value: invoicedValue,
            color: Theme.of(context).colorScheme.primary,
            percent: (proformasValue + invoicedValue) > 0
                ? (invoicedValue / (proformasValue + invoicedValue)).clamp(
                    0.4,
                    0.8,
                  )
                : 0.6,
          ),
        ],
      ),
    );
  }
}

class _FunnelStep extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final double percent;

  const _FunnelStep({
    required this.label,
    required this.value,
    required this.color,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  CurrencyFormatter.format(value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBreakdownChart extends StatelessWidget {
  final List<Invoice> invoices;
  const _StatusBreakdownChart({required this.invoices});

  @override
  Widget build(BuildContext context) {
    final statusCounts = <InvoiceStatus, int>{};
    for (var i in invoices) {
      statusCounts[i.status] = (statusCounts[i.status] ?? 0) + 1;
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: InvoiceStatus.values.map((status) {
                  final count = statusCounts[status] ?? 0;
                  final color = _getStatusColor(status);
                  return PieChartSectionData(
                    color: color,
                    value: count.toDouble(),
                    title: count > 0 ? count.toString() : '',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: InvoiceStatus.values.map((status) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status.name.toUpperCase(),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.sent:
        return Colors.blue;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.cancelled:
        return Colors.grey;
      case InvoiceStatus.draft:
        return Colors.orange;
    }
  }
}

class _TopClientsList extends StatelessWidget {
  final List<Invoice> invoices;
  const _TopClientsList({required this.invoices});

  @override
  Widget build(BuildContext context) {
    final clientRevenue = <String, double>{};
    final clientNames = <String, String>{};

    for (var i in invoices) {
      clientRevenue[i.client.id] = (clientRevenue[i.client.id] ?? 0) + i.total;
      clientNames[i.client.id] = i.client.name;
    }

    final sortedClients = clientRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topClients = sortedClients.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: topClients.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.1),
        ),
        itemBuilder: (context, index) {
          final client = topClients[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                clientNames[client.key]![0],
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            title: Text(
              clientNames[client.key]!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              CurrencyFormatter.format(client.value),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
