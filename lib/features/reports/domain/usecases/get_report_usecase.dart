// fpdart exports an `Order` typeclass that collides with our sale entity.
import 'package:fpdart/fpdart.dart' hide Order;

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/date_range.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/repositories/order_repository.dart';
import '../entities/report_summary.dart';

/// Builds every figure the dashboard, Z-report and PDF show, from one place —
/// so those three can never end up disagreeing with each other.
class GetReportUseCase implements UseCase<ReportSummary, DateRange> {
  final OrderRepository orderRepository;
  final ExpenseRepository expenseRepository;

  GetReportUseCase({
    required this.orderRepository,
    required this.expenseRepository,
  });

  @override
  Future<Either<Failure, ReportSummary>> call(DateRange range) async {
    final ordersResult =
        await orderRepository.getOrdersInRange(range.from, range.to);

    return ordersResult.fold(
      (failure) async => Left<Failure, ReportSummary>(failure),
      (orders) async {
        final expensesResult =
            await expenseRepository.getExpensesInRange(range.from, range.to);

        return expensesResult.fold(
          (failure) => Left<Failure, ReportSummary>(failure),
          (expenses) =>
              Right<Failure, ReportSummary>(build(range, orders, expenses)),
        );
      },
    );
  }

  /// Pure aggregation, separated so it can be unit-tested without Hive.
  static ReportSummary build(
    DateRange range,
    List<Order> allOrders,
    List<Expense> expenses,
  ) {
    // `.counted` is the single definition of what counts as money taken.
    final orders = allOrders.counted.toList();
    final voided = allOrders.voidedOnly.toList();

    final revenue = orders.fold<double>(0, (sum, o) => sum + o.total);
    final totalExpenses = expenses.total;

    return ReportSummary(
      range: range,
      revenue: revenue,
      expenses: totalExpenses,
      orderCount: orders.length,
      topItems: _topItems(orders),
      perStaff: _perStaff(orders),
      buckets: _buckets(range, orders, expenses),
      expensesByCategory: expenses.byCategory,
      voidedCount: voided.length,
      voidedValue: voided.fold<double>(0, (sum, o) => sum + o.total),
    );
  }

  /// Ranked by revenue, then by quantity — the item that makes the most money
  /// is the more useful headline than the one that moves the most units.
  static List<ItemSales> _topItems(List<Order> orders) {
    final quantities = <String, int>{};
    final revenues = <String, double>{};
    final names = <String, String>{};

    for (final order in orders) {
      for (final line in order.lines) {
        final key = line.reportKey;
        quantities[key] = (quantities[key] ?? 0) + line.quantity;
        revenues[key] = (revenues[key] ?? 0) + line.lineTotal;
        names[key] = line.displayName;
      }
    }

    final items = quantities.keys
        .map((key) => ItemSales(
              key: key,
              name: names[key] ?? '',
              quantity: quantities[key] ?? 0,
              revenue: revenues[key] ?? 0,
            ))
        .toList()
      ..sort((a, b) {
        final byRevenue = b.revenue.compareTo(a.revenue);
        return byRevenue != 0
            ? byRevenue
            : b.quantity.compareTo(a.quantity);
      });

    return items;
  }

  static List<StaffSales> _perStaff(List<Order> orders) {
    final counts = <String, int>{};
    final revenues = <String, double>{};
    final names = <String, String>{};

    for (final order in orders) {
      final id = order.createdByStaffId;
      counts[id] = (counts[id] ?? 0) + 1;
      revenues[id] = (revenues[id] ?? 0) + order.total;
      // The name stored on the order, so deactivated staff still show up.
      names[id] = order.createdByStaffName;
    }

    return counts.keys
        .map((id) => StaffSales(
              staffId: id,
              staffName: names[id] ?? 'Unknown',
              orderCount: counts[id] ?? 0,
              revenue: revenues[id] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
  }

  /// One bucket per day in the range, including days with no activity so the
  /// chart shows real gaps rather than silently compressing them.
  static List<DayBucket> _buckets(
    DateRange range,
    List<Order> orders,
    List<Expense> expenses,
  ) {
    final revenueByDay = <DateTime, double>{};
    final countByDay = <DateTime, int>{};
    final expensesByDay = <DateTime, double>{};

    for (final order in orders) {
      final day = DateRange.startOfDay(order.createdAt);
      revenueByDay[day] = (revenueByDay[day] ?? 0) + order.total;
      countByDay[day] = (countByDay[day] ?? 0) + 1;
    }

    for (final expense in expenses) {
      final day = DateRange.startOfDay(expense.createdAt);
      expensesByDay[day] = (expensesByDay[day] ?? 0) + expense.amount;
    }

    return range.days
        .map((day) => DayBucket(
              day: day,
              revenue: revenueByDay[day] ?? 0,
              expenses: expensesByDay[day] ?? 0,
              orderCount: countByDay[day] ?? 0,
            ))
        .toList();
  }
}
