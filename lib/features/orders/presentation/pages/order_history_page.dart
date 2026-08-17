import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/currency.dart';
import '../../domain/entities/order.dart';
import '../bloc/order_history_bloc.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<OrderHistoryBloc>().add(const LoadRecentOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Order History',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          BlocBuilder<OrderHistoryBloc, OrderHistoryState>(
            builder: (context, state) {
              if (state.hiddenVoidedCount == 0 && !state.showVoided) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () =>
                    context.read<OrderHistoryBloc>().add(ToggleShowVoided()),
                child: Text(state.showVoided ? 'Hide voided' : 'Show voided'),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<OrderHistoryBloc, OrderHistoryState>(
        listener: (context, state) {
          if (state.message == null) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message!),
            backgroundColor: state.status == OrderHistoryStatus.error
                ? Colors.red
                : Colors.green,
          ));
        },
        builder: (context, state) {
          if (state.status == OrderHistoryStatus.loading &&
              state.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final grouped = state.groupedByDay;
          if (grouped.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No orders yet. Completed orders show up here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          final days = grouped.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return RefreshIndicator(
            onRefresh: () async => context
                .read<OrderHistoryBloc>()
                .add(const LoadRecentOrders()),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final orders = grouped[day]!;
                return _DaySection(day: day, orders: orders);
              },
            ),
          );
        },
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final DateTime day;
  final List<Order> orders;

  const _DaySection({required this.day, required this.orders});

  @override
  Widget build(BuildContext context) {
    // The per-day total counts only orders that stand — voided ones are
    // listed but never added up.
    final dayTotal = orders.revenue;
    final countedOrders = orders.counted.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _dayLabel(day),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                '$countedOrders ${countedOrders == 1 ? 'order' : 'orders'} · '
                '${money(dayTotal)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        ...orders.map((order) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OrderTile(order: order),
            )),
      ],
    );
  }

  static String _dayLabel(DateTime day) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final yesterday =
        DateTime(today.year, today.month, today.day - 1);

    if (day == startOfToday) return 'Today';
    if (day == yesterday) return 'Yesterday';
    return DateFormat('EEEE, d MMMM').format(day);
  }
}

class OrderTile extends StatelessWidget {
  final Order order;

  const OrderTile({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: order.voided ? 0.55 : 1,
      child: InkWell(
        onTap: () =>
            context.push('/history/order/${order.id}', extra: order),
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
                    Row(
                      children: [
                        Text('#${order.orderNumber}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('HH:mm').format(order.createdAt),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                        if (order.voided) ...[
                          const SizedBox(width: 8),
                          const _Badge(text: 'VOID', color: Colors.red),
                        ],
                        if (order.wasEdited && !order.voided) ...[
                          const SizedBox(width: 8),
                          const _Badge(
                              text: 'EDITED', color: Colors.orange),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.itemCount} '
                      '${order.itemCount == 1 ? 'item' : 'items'} · '
                      '${order.createdByStaffName}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                money(order.total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  decoration:
                      order.voided ? TextDecoration.lineThrough : null,
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
