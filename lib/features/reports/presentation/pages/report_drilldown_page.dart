import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/currency.dart';
import '../../../../core/utils/date_range.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/presentation/bloc/expense_bloc.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/bloc/order_history_bloc.dart';
import '../../../orders/presentation/pages/order_history_page.dart';

/// The orders and expenses behind a dashboard figure.
class ReportDrilldownPage extends StatefulWidget {
  final DateRange range;
  final int initialTab;

  const ReportDrilldownPage({
    super.key,
    required this.range,
    this.initialTab = 0,
  });

  @override
  State<ReportDrilldownPage> createState() => _ReportDrilldownPageState();
}

class _ReportDrilldownPageState extends State<ReportDrilldownPage> {
  late final OrderHistoryBloc _orderBloc;
  late final ExpenseBloc _expenseBloc;

  @override
  void initState() {
    super.initState();
    // Captured here rather than looked up in dispose(), where the element is
    // already deactivated and `context.read` is not safe.
    _orderBloc = context.read<OrderHistoryBloc>();
    _expenseBloc = context.read<ExpenseBloc>();

    _orderBloc.add(LoadOrdersInRange(widget.range));
    _expenseBloc.add(LoadExpensesInRange(widget.range));
  }

  @override
  void dispose() {
    // Leave both lists back on their default view, so opening the History tab
    // afterwards doesn't silently show a stale filtered period.
    _orderBloc.add(const LoadRecentOrders());
    _expenseBloc.add(LoadRecentExpenses());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 28, color: Theme.of(context).primaryColor),
            onPressed: () => context.pop(),
          ),
          title: Column(
            children: [
              Text(widget.range.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17)),
              Text(
                _rangeSubtitle(widget.range),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Orders'),
              Tab(text: 'Expenses'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrders(),
            _buildExpenses(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrders() {
    return BlocBuilder<OrderHistoryBloc, OrderHistoryState>(
      builder: (context, state) {
        if (state.status == OrderHistoryStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = state.orders;
        if (orders.isEmpty) {
          return const _EmptyMessage('No orders in this period.');
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _TotalStrip(
              label: '${orders.counted.length} orders',
              value: money(orders.revenue),
            ),
            const SizedBox(height: 12),
            ...orders.map((order) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OrderTile(order: order),
                )),
          ],
        );
      },
    );
  }

  Widget _buildExpenses() {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        if (state.status == ExpenseStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses = state.expenses;
        if (expenses.isEmpty) {
          return const _EmptyMessage('No expenses in this period.');
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _TotalStrip(
              label: '${expenses.length} entries',
              value: money(expenses.total),
            ),
            const SizedBox(height: 12),
            ...expenses.map((expense) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(expense.category,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                              '${DateFormat('d MMM').format(expense.createdAt)}'
                              '${expense.note.isEmpty ? '' : ' · ${expense.note}'}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Text(money(expense.amount),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB91C1C))),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  static String _rangeSubtitle(DateRange range) {
    final format = DateFormat('d MMM');
    final lastDay = range.days.last;
    if (range.dayCount == 1) return format.format(range.from);
    return '${format.format(range.from)} – ${format.format(lastDay)}';
  }
}

class _TotalStrip extends StatelessWidget {
  final String label;
  final String value;

  const _TotalStrip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String message;
  const _EmptyMessage(this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}
