import 'package:equatable/equatable.dart';

/// Money going out — stock, rent, wages, utilities.
///
/// Logged by hand rather than derived from per-item costs, so the dashboard
/// can show the whole picture: what the shop took, what it spent, and what is
/// left.
class Expense extends Equatable {
  final String id;

  /// The date the money went out. Back-dating is allowed, so this is not
  /// necessarily when the entry was typed in.
  final DateTime createdAt;

  final double amount;
  final String category;
  final String note;

  final String createdByStaffId;
  final String createdByStaffName;

  const Expense({
    required this.id,
    required this.createdAt,
    required this.amount,
    required this.category,
    this.note = '',
    required this.createdByStaffId,
    required this.createdByStaffName,
  });

  @override
  List<Object?> get props => [
        id,
        createdAt,
        amount,
        category,
        note,
        createdByStaffId,
        createdByStaffName,
      ];
}

class ExpenseCategories {
  const ExpenseCategories._();

  static const String supplies = 'Supplies';
  static const String rent = 'Rent';
  static const String salary = 'Salary';
  static const String utilities = 'Utilities';
  static const String other = 'Other';

  static const List<String> all = [
    supplies,
    rent,
    salary,
    utilities,
    other,
  ];
}

extension ExpenseIterableX on Iterable<Expense> {
  double get total => fold(0.0, (sum, expense) => sum + expense.amount);

  Map<String, double> get byCategory {
    final totals = <String, double>{};
    for (final expense in this) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }
}
