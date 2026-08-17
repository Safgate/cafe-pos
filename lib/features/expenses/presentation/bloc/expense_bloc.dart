import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/session/current_session.dart';
import '../../../../core/utils/date_range.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

part 'expense_event.dart';
part 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository repository;

  ExpenseBloc({required this.repository}) : super(const ExpenseState()) {
    on<LoadRecentExpenses>(_onLoadRecent);
    on<LoadExpensesInRange>(_onLoadRange);
    on<AddExpense>(_onAddExpense);
    on<DeleteExpense>(_onDeleteExpense);
  }

  Future<void> _onLoadRecent(
      LoadRecentExpenses event, Emitter<ExpenseState> emit) async {
    emit(state.copyWith(status: ExpenseStatus.loading, clearMessage: true));
    final result = await repository.getRecentExpenses();
    result.fold(
      (failure) => emit(state.copyWith(
          status: ExpenseStatus.error, message: failure.message)),
      (expenses) => emit(state.copyWith(
          status: ExpenseStatus.loaded,
          expenses: expenses,
          clearRange: true)),
    );
  }

  Future<void> _onLoadRange(
      LoadExpensesInRange event, Emitter<ExpenseState> emit) async {
    emit(state.copyWith(status: ExpenseStatus.loading, clearMessage: true));
    final result =
        await repository.getExpensesInRange(event.range.from, event.range.to);
    result.fold(
      (failure) => emit(state.copyWith(
          status: ExpenseStatus.error, message: failure.message)),
      (expenses) => emit(state.copyWith(
        status: ExpenseStatus.loaded,
        expenses: expenses,
        range: event.range,
      )),
    );
  }

  Future<void> _onAddExpense(
      AddExpense event, Emitter<ExpenseState> emit) async {
    final expense = Expense(
      id: const Uuid().v4(),
      createdAt: event.date,
      amount: event.amount,
      category: event.category,
      note: event.note,
      createdByStaffId: CurrentSession.staffId,
      createdByStaffName: CurrentSession.staffName,
    );

    final result = await repository.addExpense(expense);
    await result.fold(
      (failure) async => emit(state.copyWith(
          status: ExpenseStatus.error, message: failure.message)),
      (_) async {
        emit(state.copyWith(
            status: ExpenseStatus.success, message: 'Expense logged'));
        _reload();
      },
    );
  }

  Future<void> _onDeleteExpense(
      DeleteExpense event, Emitter<ExpenseState> emit) async {
    final result = await repository.deleteExpense(event.id);
    await result.fold(
      (failure) async => emit(state.copyWith(
          status: ExpenseStatus.error, message: failure.message)),
      (_) async {
        emit(state.copyWith(
            status: ExpenseStatus.success, message: 'Expense deleted'));
        _reload();
      },
    );
  }

  void _reload() {
    if (state.range != null) {
      add(LoadExpensesInRange(state.range!));
    } else {
      add(LoadRecentExpenses());
    }
  }
}
