part of 'expense_bloc.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();
  @override
  List<Object?> get props => [];
}

class LoadRecentExpenses extends ExpenseEvent {}

class LoadExpensesInRange extends ExpenseEvent {
  final DateRange range;
  const LoadExpensesInRange(this.range);
  @override
  List<Object?> get props => [range];
}

class AddExpense extends ExpenseEvent {
  final double amount;
  final String category;
  final String note;

  /// Allowed to be in the past — a receipt logged on Friday may be for
  /// Tuesday's delivery.
  final DateTime date;

  const AddExpense({
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
  });

  @override
  List<Object?> get props => [amount, category, note, date];
}

class DeleteExpense extends ExpenseEvent {
  final String id;
  const DeleteExpense(this.id);
  @override
  List<Object?> get props => [id];
}
