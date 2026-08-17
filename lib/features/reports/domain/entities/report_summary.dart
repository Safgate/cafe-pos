import 'package:equatable/equatable.dart';
import '../../../../core/utils/date_range.dart';

/// Sales of one menu item at one size, over the report period.
class ItemSales extends Equatable {
  final String key;
  final String name;
  final int quantity;
  final double revenue;

  const ItemSales({
    required this.key,
    required this.name,
    required this.quantity,
    required this.revenue,
  });

  @override
  List<Object?> get props => [key, name, quantity, revenue];
}

/// What one staff member rang up over the period.
class StaffSales extends Equatable {
  final String staffId;
  final String staffName;
  final int orderCount;
  final double revenue;

  const StaffSales({
    required this.staffId,
    required this.staffName,
    required this.orderCount,
    required this.revenue,
  });

  @override
  List<Object?> get props => [staffId, staffName, orderCount, revenue];
}

/// One day's figures — a bar on the chart.
class DayBucket extends Equatable {
  final DateTime day;
  final double revenue;
  final double expenses;
  final int orderCount;

  const DayBucket({
    required this.day,
    required this.revenue,
    required this.expenses,
    required this.orderCount,
  });

  double get profit => revenue - expenses;

  @override
  List<Object?> get props => [day, revenue, expenses, orderCount];
}

class ReportSummary extends Equatable {
  final DateRange range;

  /// Voided orders are excluded from [revenue], [orderCount] and
  /// [averageOrderValue], and from every bucket and breakdown below.
  final double revenue;
  final double expenses;
  final int orderCount;

  final List<ItemSales> topItems;
  final List<StaffSales> perStaff;
  final List<DayBucket> buckets;
  final Map<String, double> expensesByCategory;

  /// Surfaced rather than buried — a climbing void count is exactly what an
  /// owner needs to notice.
  final int voidedCount;
  final double voidedValue;

  const ReportSummary({
    required this.range,
    required this.revenue,
    required this.expenses,
    required this.orderCount,
    required this.topItems,
    required this.perStaff,
    required this.buckets,
    required this.expensesByCategory,
    required this.voidedCount,
    required this.voidedValue,
  });

  double get profit => revenue - expenses;

  double get averageOrderValue =>
      orderCount == 0 ? 0 : revenue / orderCount;

  bool get isEmpty => orderCount == 0 && expenses == 0;

  factory ReportSummary.empty(DateRange range) => ReportSummary(
        range: range,
        revenue: 0,
        expenses: 0,
        orderCount: 0,
        topItems: const [],
        perStaff: const [],
        buckets: const [],
        expensesByCategory: const {},
        voidedCount: 0,
        voidedValue: 0,
      );

  @override
  List<Object?> get props => [
        range,
        revenue,
        expenses,
        orderCount,
        topItems,
        perStaff,
        buckets,
        expensesByCategory,
        voidedCount,
        voidedValue,
      ];
}
