// fpdart exports an `Order` typeclass that collides with our sale entity.
import 'package:fpdart/fpdart.dart' hide Order;
import '../../../../core/error/failure.dart';
import '../entities/order.dart';

abstract class OrderRepository {
  Future<Either<Failure, void>> saveOrder(Order order);

  /// Replaces an order's lines and total, bumping its revision. The caller
  /// passes [before] so the activity log can record what actually changed.
  Future<Either<Failure, void>> updateOrder({
    required Order before,
    required Order updated,
  });

  /// Marks an order voided. The record is kept — see [Order].
  Future<Either<Failure, void>> voidOrder({
    required String id,
    required String reason,
  });

  /// [from] inclusive, [to] exclusive. Includes voided orders so callers can
  /// report on them; use `.counted` to exclude them from money figures.
  Future<Either<Failure, List<Order>>> getOrdersInRange(
    DateTime from,
    DateTime to,
  );

  Future<Either<Failure, List<Order>>> getRecentOrders({int limit = 200});

  Future<Either<Failure, Order?>> getById(String id);

  /// Next ticket number for today. Resets at midnight.
  Future<int> nextOrderNumber();

  /// Records that a receipt was reprinted.
  Future<void> logReprint(Order order);
}
