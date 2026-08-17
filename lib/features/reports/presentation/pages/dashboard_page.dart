import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/date_range.dart';
import '../../../shop/domain/entities/shop.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../data/report_exporter.dart';
import '../../domain/entities/report_summary.dart';
import '../bloc/report_bloc.dart';
import '../widgets/period_bar_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    context.read<ReportBloc>().add(const LoadReport());
  }

  Shop get _shop {
    final state = context.read<ShopBloc>().state;
    return state is ShopLoaded ? state.shop : const Shop();
  }

  Future<void> _runExport(
      Future<ExportResult> Function(ReportExporter) action) async {
    setState(() => _exporting = true);
    final result = await action(sl<ReportExporter>());
    if (!mounted) return;
    setState(() => _exporting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.message),
      backgroundColor: result.success ? Colors.green : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: BlocBuilder<ReportBloc, ReportState>(
        builder: (context, state) {
          final summary = state.summary;

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<ReportBloc>().add(const LoadReport()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                _buildPeriodSelector(context, state),
                const SizedBox(height: 20),
                if (state.status == ReportStatus.loading && summary == null)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.status == ReportStatus.error)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(state.message ?? 'Something went wrong',
                          style: const TextStyle(color: Colors.red)),
                    ),
                  )
                else if (summary != null) ...[
                  _buildHeadlineCards(context, summary),
                  const SizedBox(height: 24),
                  _buildCard(
                    title: 'Revenue by day',
                    child: PeriodBarChart(
                      buckets: summary.buckets,
                      onBarTap: (bucket) => _openDrilldown(
                          DateRange.day(bucket.day), 0),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatsRow(summary),
                  const SizedBox(height: 16),
                  if (summary.topItems.isNotEmpty) ...[
                    _buildTopItems(summary),
                    const SizedBox(height: 16),
                  ],
                  if (summary.perStaff.isNotEmpty) ...[
                    _buildPerStaff(summary),
                    const SizedBox(height: 16),
                  ],
                  if (summary.expensesByCategory.isNotEmpty) ...[
                    _buildExpenseBreakdown(summary),
                    const SizedBox(height: 16),
                  ],
                  _buildVoidNote(summary),
                  const SizedBox(height: 24),
                  _buildExportButtons(summary),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, ReportState state) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ReportPeriod.values.map((period) {
          final selected = state.period == period;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  context.read<ReportBloc>().add(ChangeReportPeriod(period)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 1))
                        ]
                      : null,
                ),
                child: Text(
                  period.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppTheme.primaryColor
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeadlineCards(BuildContext context, ReportSummary summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FigureCard(
                label: 'Revenue',
                value: money(summary.revenue),
                color: const Color(0xFF16A34A),
                onTap: () => _openDrilldown(summary.range, 0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FigureCard(
                label: 'Expenses',
                value: money(summary.expenses),
                color: const Color(0xFFDC2626),
                onTap: () => _openDrilldown(summary.range, 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _FigureCard(
          label: summary.profit >= 0 ? 'Profit' : 'Loss',
          value: money(summary.profit),
          color: summary.profit >= 0
              ? AppTheme.primaryColor
              : const Color(0xFFDC2626),
          wide: true,
        ),
      ],
    );
  }

  Widget _buildStatsRow(ReportSummary summary) {
    return _buildCard(
      title: 'At a glance',
      child: Column(
        children: [
          _statRow('Orders', '${summary.orderCount}'),
          _statRow('Average order', money(summary.averageOrderValue)),
          _statRow(
            'Days in period',
            '${summary.range.dayCount}',
          ),
        ],
      ),
    );
  }

  Widget _buildTopItems(ReportSummary summary) {
    return _buildCard(
      title: 'Top sellers',
      child: Column(
        children: summary.topItems
            .take(6)
            .map((item) => _statRow(
                  '${item.quantity}x  ${item.name}',
                  money(item.revenue),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildPerStaff(ReportSummary summary) {
    return _buildCard(
      title: 'By staff',
      child: Column(
        children: summary.perStaff
            .map((staff) => _statRow(
                  '${staff.staffName} · ${staff.orderCount} orders',
                  money(staff.revenue),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildExpenseBreakdown(ReportSummary summary) {
    final entries = summary.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildCard(
      title: 'Where it went',
      child: Column(
        children:
            entries.map((e) => _statRow(e.key, money(e.value))).toList(),
      ),
    );
  }

  /// Voids are shown, not hidden. A rising count is worth an owner's
  /// attention.
  Widget _buildVoidNote(ReportSummary summary) {
    if (summary.voidedCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.block, size: 18, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${summary.voidedCount} voided '
              '${summary.voidedCount == 1 ? 'order' : 'orders'} worth '
              '${money(summary.voidedValue)} — not counted above.',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButtons(ReportSummary summary) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: _exporting
              ? null
              : () => _runExport((exporter) => exporter.printSummary(
                    summary: summary,
                    shop: _shop,
                  )),
          icon: const Icon(Icons.receipt_long),
          label: const Text('Print Summary'),
          style:
              OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _exporting
              ? null
              : () => _runExport((exporter) => exporter.sharePdf(
                    summary: summary,
                    shop: _shop,
                  )),
          icon: _exporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.picture_as_pdf),
          label: const Text('Export PDF'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  void _openDrilldown(DateRange range, int tab) {
    context.push('/dashboard/detail', extra: {'range': range, 'tab': tab});
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FigureCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final bool wide;

  const _FigureCard({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.bold,
                      color: color.withValues(alpha: 0.8)),
                ),
                if (onTap != null) ...[
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 16, color: color),
                ],
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: wide ? 30 : 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
