import 'package:cafe_pos/core/utils/date_range.dart';
import 'package:cafe_pos/features/expenses/domain/entities/expense.dart';
import 'package:cafe_pos/features/orders/domain/entities/order.dart';
import 'package:cafe_pos/features/orders/domain/entities/order_line.dart';
import 'package:cafe_pos/features/reports/domain/usecases/get_report_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

/// 13 Aug 2026 is a Thursday; the week runs Mon 10th – Sun 16th.
final _thursday = DateTime(2026, 8, 13, 10, 0);
final _friday = DateTime(2026, 8, 14, 10, 0);

Order _order({
  required int number,
  required DateTime at,
  required List<OrderLine> lines,
  bool voided = false,
  String staffId = 'staff-1',
  String staffName = 'Sam',
}) {
  final total = lines.fold<double>(0, (sum, l) => sum + l.lineTotal);
  return Order(
    id: 'order-$number',
    orderNumber: number,
    createdAt: at,
    lines: lines,
    total: total,
    createdByStaffId: staffId,
    createdByStaffName: staffName,
    voided: voided,
    voidReason: voided ? 'spilled' : '',
  );
}

OrderLine _line(String name, double price, int qty, {String size = ''}) {
  return OrderLine(
    productId: name.toLowerCase(),
    itemName: name,
    variantLabel: size,
    unitPrice: price,
    quantity: qty,
  );
}

Expense _expense(double amount, String category, DateTime at) {
  return Expense(
    id: 'expense-${at.millisecondsSinceEpoch}-$amount',
    createdAt: at,
    amount: amount,
    category: category,
    createdByStaffId: 'staff-1',
    createdByStaffName: 'Sam',
  );
}

void main() {
  final week = DateRange.thisWeek(_thursday);

  group('revenue, expenses and profit', () {
    test('profit is revenue minus expenses', () {
      final summary = GetReportUseCase.build(
        week,
        [
          _order(number: 1, at: _thursday, lines: [_line('Latte', 3.20, 2)]),
          _order(number: 2, at: _friday, lines: [_line('Croissant', 2.50, 1)]),
        ],
        [_expense(45.00, ExpenseCategories.supplies, _thursday)],
      );

      expect(summary.revenue, closeTo(8.90, 0.001));
      expect(summary.expenses, closeTo(45.00, 0.001));
      expect(summary.profit, closeTo(-36.10, 0.001));
      expect(summary.orderCount, 2);
    });

    test('average order value divides revenue by the counted orders', () {
      final summary = GetReportUseCase.build(
        week,
        [
          _order(number: 1, at: _thursday, lines: [_line('Latte', 3.00, 1)]),
          _order(number: 2, at: _thursday, lines: [_line('Latte', 5.00, 1)]),
        ],
        [],
      );

      expect(summary.averageOrderValue, closeTo(4.00, 0.001));
    });

    test('an empty period reports zero rather than dividing by zero', () {
      final summary = GetReportUseCase.build(week, [], []);

      expect(summary.revenue, 0);
      expect(summary.averageOrderValue, 0);
      expect(summary.isEmpty, isTrue);
    });
  });

  group('voided orders', () {
    test('are excluded from revenue, order count and average', () {
      final summary = GetReportUseCase.build(
        week,
        [
          _order(number: 1, at: _thursday, lines: [_line('Latte', 3.00, 1)]),
          _order(
            number: 2,
            at: _thursday,
            lines: [_line('Latte', 100.00, 1)],
            voided: true,
          ),
        ],
        [],
      );

      expect(summary.revenue, closeTo(3.00, 0.001));
      expect(summary.orderCount, 1);
      expect(summary.averageOrderValue, closeTo(3.00, 0.001));
    });

    test('are still reported separately, not silently dropped', () {
      final summary = GetReportUseCase.build(
        week,
        [
          _order(
            number: 1,
            at: _thursday,
            lines: [_line('Latte', 12.50, 1)],
            voided: true,
          ),
        ],
        [],
      );

      expect(summary.voidedCount, 1);
      expect(summary.voidedValue, closeTo(12.50, 0.001));
    });

    test('do not contribute to top items or the staff breakdown', () {
      final summary = GetReportUseCase.build(
        week,
        [
          _order(
            number: 1,
            at: _thursday,
            lines: [_line('Ghost', 99.00, 5)],
            voided: true,
          ),
        ],
        [],
      );

      expect(summary.topItems, isEmpty);
      expect(summary.perStaff, isEmpty);
    });

    test('do not appear in the daily buckets', () {
      final summary = GetReportUseCase.build(
        week,
        [
          _order(
            number: 1,
            at: _thursday,
            lines: [_line('Latte', 40.00, 1)],
            voided: true,
          ),
        ],
        [],
      );

      final thursdayBucket = summary.buckets
          .firstWhere((b) => b.day == DateTime(2026, 8, 13));
      expect(thursdayBucket.revenue, 0);
      expect(thursdayBucket.orderCount, 0);
    });
  });

  group('top items', () {
    test('ranks by revenue, and keeps sizes apart', () {
      final summary = GetReportUseCase.build(
        week,
        [
          _order(number: 1, at: _thursday, lines: [
            _line('Latte', 2.80, 10, size: 'Small'), // 28.00
            _line('Latte', 3.60, 10, size: 'Large'), // 36.00
            _line('Croissant', 2.50, 4), // 10.00
          ]),
        ],
        [],
      );

      expect(summary.topItems.first.name, 'Latte (Large)');
      expect(summary.topItems.first.revenue, closeTo(36.00, 0.001));
      expect(summary.topItems[1].name, 'Latte (Small)');
      expect(summary.topItems.last.name, 'Croissant');
      expect(summary.topItems.length, 3);
    });

    test('adds up quantities of the same item across orders', () {
      final summary = GetReportUseCase.build(
        week,
        [
          _order(number: 1, at: _thursday, lines: [_line('Latte', 3.00, 2)]),
          _order(number: 2, at: _friday, lines: [_line('Latte', 3.00, 3)]),
        ],
        [],
      );

      expect(summary.topItems.single.quantity, 5);
      expect(summary.topItems.single.revenue, closeTo(15.00, 0.001));
    });
  });

  group('staff breakdown', () {
    test('groups by staff and uses the name stored on the order', () {
      final summary = GetReportUseCase.build(
        week,
        [
          _order(number: 1, at: _thursday, lines: [_line('Latte', 3.00, 1)]),
          _order(
            number: 2,
            at: _thursday,
            lines: [_line('Latte', 9.00, 1)],
            staffId: 'staff-2',
            staffName: 'Alex',
          ),
        ],
        [],
      );

      expect(summary.perStaff.first.staffName, 'Alex');
      expect(summary.perStaff.first.revenue, closeTo(9.00, 0.001));
      expect(summary.perStaff.last.staffName, 'Sam');
      expect(summary.perStaff.last.orderCount, 1);
    });
  });

  group('daily buckets', () {
    test('cover every day in the range, including quiet ones', () {
      final summary = GetReportUseCase.build(
        week,
        [_order(number: 1, at: _thursday, lines: [_line('Latte', 3.00, 1)])],
        [],
      );

      expect(summary.buckets.length, 7);
      expect(summary.buckets.where((b) => b.revenue > 0).length, 1);
    });

    test('land expenses on the day the money went out', () {
      final summary = GetReportUseCase.build(
        week,
        [],
        [
          _expense(20.00, ExpenseCategories.supplies, _thursday),
          _expense(5.00, ExpenseCategories.utilities, _friday),
        ],
      );

      final thursday = summary.buckets
          .firstWhere((b) => b.day == DateTime(2026, 8, 13));
      final friday =
          summary.buckets.firstWhere((b) => b.day == DateTime(2026, 8, 14));

      expect(thursday.expenses, closeTo(20.00, 0.001));
      expect(friday.expenses, closeTo(5.00, 0.001));
    });

    test('a late-evening sale lands on that day, not the next', () {
      final lateSale = DateTime(2026, 8, 13, 23, 45);
      final summary = GetReportUseCase.build(
        week,
        [_order(number: 1, at: lateSale, lines: [_line('Latte', 3.00, 1)])],
        [],
      );

      final thursday = summary.buckets
          .firstWhere((b) => b.day == DateTime(2026, 8, 13));
      expect(thursday.orderCount, 1);
    });
  });

  group('expenses by category', () {
    test('totals each category', () {
      final summary = GetReportUseCase.build(
        week,
        [],
        [
          _expense(10.00, ExpenseCategories.supplies, _thursday),
          _expense(15.00, ExpenseCategories.supplies, _friday),
          _expense(400.00, ExpenseCategories.rent, _thursday),
        ],
      );

      expect(summary.expensesByCategory[ExpenseCategories.supplies],
          closeTo(25.00, 0.001));
      expect(summary.expensesByCategory[ExpenseCategories.rent],
          closeTo(400.00, 0.001));
    });
  });
}
