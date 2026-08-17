part of 'expense_bloc.dart';

enum ExpenseStatus { initial, loading, loaded, success, error }

class ExpenseState extends Equatable {
  final List<Expense> expenses;
  final ExpenseStatus status;
  final String? message;
  final DateRange? range;

  const ExpenseState({
    this.expenses = const [],
    this.status = ExpenseStatus.initial,
    this.message,
    this.range,
  });

  double get total => expenses.total;

  Map<DateTime, List<Expense>> get groupedByDay {
    final grouped = <DateTime, List<Expense>>{};
    for (final expense in expenses) {
      final day = DateRange.startOfDay(expense.createdAt);
      grouped.putIfAbsent(day, () => []).add(expense);
    }
    return grouped;
  }

  ExpenseState copyWith({
    List<Expense>? expenses,
    ExpenseStatus? status,
    String? message,
    bool clearMessage = false,
    DateRange? range,
    bool clearRange = false,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
      range: clearRange ? null : (range ?? this.range),
    );
  }

  @override
  List<Object?> get props => [expenses, status, message, range];
}
