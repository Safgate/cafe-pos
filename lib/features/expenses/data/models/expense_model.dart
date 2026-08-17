import 'package:hive/hive.dart';
import '../../domain/entities/expense.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 5)
class ExpenseModel extends Expense {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final DateTime createdAt;
  @override
  @HiveField(2)
  final double amount;

  /// Stored as a plain string so adding a category later needs no adapter.
  @override
  @HiveField(3)
  final String category;

  @override
  @HiveField(4)
  final String note;
  @override
  @HiveField(5)
  final String createdByStaffId;
  @override
  @HiveField(6)
  final String createdByStaffName;

  const ExpenseModel({
    required this.id,
    required this.createdAt,
    required this.amount,
    required this.category,
    required this.note,
    required this.createdByStaffId,
    required this.createdByStaffName,
  }) : super(
          id: id,
          createdAt: createdAt,
          amount: amount,
          category: category,
          note: note,
          createdByStaffId: createdByStaffId,
          createdByStaffName: createdByStaffName,
        );

  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      createdAt: expense.createdAt,
      amount: expense.amount,
      category: expense.category,
      note: expense.note,
      createdByStaffId: expense.createdByStaffId,
      createdByStaffName: expense.createdByStaffName,
    );
  }

  Expense toEntity() => this;
}
