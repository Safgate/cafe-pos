import 'package:fpdart/fpdart.dart';

import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/activity_logger.dart';
import '../../../../core/utils/currency.dart';
import '../../../activity/domain/entities/activity_log.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ActivityLogger logger;

  ExpenseRepositoryImpl(this.logger);

  @override
  Future<Either<Failure, void>> addExpense(Expense expense) async {
    try {
      await HiveDatabase.expenseBox
          .put(expense.id, ExpenseModel.fromEntity(expense));
      await logger.log(
        action: ActivityActions.expenseCreated,
        entityType: 'expense',
        entityId: expense.id,
        summary: '${expense.category} ${money(expense.amount)}'
            '${expense.note.isEmpty ? '' : ' — ${expense.note}'}',
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String id) async {
    try {
      final existing = HiveDatabase.expenseBox.get(id);
      if (existing == null) {
        return const Left(CacheFailure('That expense no longer exists.'));
      }

      await HiveDatabase.expenseBox.delete(id);
      await logger.log(
        action: ActivityActions.expenseDeleted,
        entityType: 'expense',
        entityId: id,
        summary: 'Deleted ${existing.category} ${money(existing.amount)}'
            '${existing.note.isEmpty ? '' : ' — ${existing.note}'}',
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesInRange(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final expenses = HiveDatabase.expenseBox.values
          .where((e) =>
              !e.createdAt.isBefore(from) && e.createdAt.isBefore(to))
          .map((e) => e.toEntity())
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(expenses);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getRecentExpenses(
      {int limit = 200}) async {
    try {
      final expenses = HiveDatabase.expenseBox.values
          .map((e) => e.toEntity())
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(expenses.take(limit).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
