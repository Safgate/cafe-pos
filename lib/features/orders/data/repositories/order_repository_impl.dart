// fpdart exports an `Order` typeclass that collides with our sale entity.
import 'package:fpdart/fpdart.dart' hide Order;

import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/activity_logger.dart';
import '../../../../core/session/current_session.dart';
import '../../../../core/utils/currency.dart';
import '../../../activity/domain/entities/activity_log.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_line.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final ActivityLogger logger;

  OrderRepositoryImpl(this.logger);

  static const String _counterDateKey = 'order_counter_date';
  static const String _counterValueKey = 'order_counter_value';

  @override
  Future<int> nextOrderNumber() async {
    final box = HiveDatabase.settingsBox;
    final today = _dateKey(DateTime.now());
    final storedDate = box.get(_counterDateKey) as String?;

    final next = storedDate == today
        ? ((box.get(_counterValueKey) as int?) ?? 0) + 1
        : 1;

    await box.put(_counterDateKey, today);
    await box.put(_counterValueKey, next);
    return next;
  }

  @override
  Future<Either<Failure, void>> saveOrder(Order order) async {
    try {
      await HiveDatabase.orderBox.put(order.id, OrderModel.fromEntity(order));
      await logger.log(
        action: ActivityActions.orderCreated,
        entityType: 'order',
        entityId: order.id,
        summary:
            'Order #${order.orderNumber} — ${order.itemCount} items, ${money(order.total)}',
        details: order.lines.map(_describeLine).join('\n'),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateOrder({
    required Order before,
    required Order updated,
  }) async {
    try {
      final revised = updated.copyWith(
        revision: before.revision + 1,
        updatedAt: DateTime.now(),
        lastEditedByStaffId: CurrentSession.staffId,
        lastEditedByStaffName: CurrentSession.staffName,
      );

      await HiveDatabase.orderBox
          .put(revised.id, OrderModel.fromEntity(revised));

      await logger.log(
        action: ActivityActions.orderEdited,
        entityType: 'order',
        entityId: revised.id,
        summary: 'Order #${revised.orderNumber} edited — '
            '${money(before.total)} to ${money(revised.total)}',
        details: _describeDiff(before, revised),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> voidOrder({
    required String id,
    required String reason,
  }) async {
    try {
      final existing = HiveDatabase.orderBox.get(id);
      if (existing == null) {
        return const Left(CacheFailure('That order no longer exists.'));
      }
      if (existing.voided) {
        return const Left(CacheFailure('That order is already voided.'));
      }

      final voided = existing.toEntity().copyWith(
            voided: true,
            voidedAt: DateTime.now(),
            voidedByStaffId: CurrentSession.staffId,
            voidedByStaffName: CurrentSession.staffName,
            voidReason: reason,
          );

      await HiveDatabase.orderBox.put(id, OrderModel.fromEntity(voided));

      await logger.log(
        action: ActivityActions.orderVoided,
        entityType: 'order',
        entityId: id,
        summary: 'Order #${voided.orderNumber} voided '
            '(${money(voided.total)}) — $reason',
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Order>>> getOrdersInRange(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final orders = HiveDatabase.orderBox.values
          .where((o) =>
              !o.createdAt.isBefore(from) && o.createdAt.isBefore(to))
          .map((o) => o.toEntity())
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(orders);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Order>>> getRecentOrders({int limit = 200}) async {
    try {
      final orders = HiveDatabase.orderBox.values
          .map((o) => o.toEntity())
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(orders.take(limit).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Order?>> getById(String id) async {
    try {
      return Right(HiveDatabase.orderBox.get(id)?.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<void> logReprint(Order order) {
    return logger.log(
      action: ActivityActions.orderReprinted,
      entityType: 'order',
      entityId: order.id,
      summary: 'Reprinted receipt for order #${order.orderNumber}',
    );
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _describeLine(OrderLine line) =>
      '${line.quantity} x ${line.displayName} @ ${money(line.unitPrice)}';

  /// Line-level before/after, so the log explains *what* changed rather than
  /// just that something did.
  static String _describeDiff(Order before, Order after) {
    final beforeByKey = {for (final l in before.lines) l.reportKey: l};
    final afterByKey = {for (final l in after.lines) l.reportKey: l};

    final changes = <String>[];

    for (final entry in afterByKey.entries) {
      final old = beforeByKey[entry.key];
      if (old == null) {
        changes.add('added ${_describeLine(entry.value)}');
      } else if (old.quantity != entry.value.quantity) {
        changes.add('${entry.value.displayName}: '
            '${old.quantity} to ${entry.value.quantity}');
      }
    }

    for (final entry in beforeByKey.entries) {
      if (!afterByKey.containsKey(entry.key)) {
        changes.add('removed ${_describeLine(entry.value)}');
      }
    }

    return changes.isEmpty ? 'No line changes' : changes.join('\n');
  }
}
