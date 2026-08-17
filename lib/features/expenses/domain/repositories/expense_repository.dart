import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/expense.dart';

abstract class ExpenseRepository {
  Future<Either<Failure, void>> addExpense(Expense expense);

  Future<Either<Failure, void>> deleteExpense(String id);

  /// [from] inclusive, [to] exclusive — matching [DateRange].
  Future<Either<Failure, List<Expense>>> getExpensesInRange(
    DateTime from,
    DateTime to,
  );

  Future<Either<Failure, List<Expense>>> getRecentExpenses({int limit = 200});
}
