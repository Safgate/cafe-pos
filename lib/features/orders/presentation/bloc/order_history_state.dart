part of 'order_history_bloc.dart';

enum OrderHistoryStatus { initial, loading, loaded, success, error }

class OrderHistoryState extends Equatable {
  final List<Order> orders;
  final OrderHistoryStatus status;
  final String? message;

  /// Non-null when the list is scoped to a period (a dashboard drill-down)
  /// rather than showing recent orders.
  final DateRange? range;

  final bool showVoided;

  const OrderHistoryState({
    this.orders = const [],
    this.status = OrderHistoryStatus.initial,
    this.message,
    this.range,
    this.showVoided = false,
  });

  /// What the list renders. Voided orders are hidden by default so day-to-day
  /// history stays clean, but they are never gone.
  List<Order> get visibleOrders =>
      showVoided ? orders : orders.counted.toList();

  int get hiddenVoidedCount => orders.voidedOnly.length;

  /// Day (local midnight) to that day's orders, newest day first.
  Map<DateTime, List<Order>> get groupedByDay {
    final grouped = <DateTime, List<Order>>{};
    for (final order in visibleOrders) {
      final day = DateRange.startOfDay(order.createdAt);
      grouped.putIfAbsent(day, () => []).add(order);
    }
    return grouped;
  }

  OrderHistoryState copyWith({
    List<Order>? orders,
    OrderHistoryStatus? status,
    String? message,
    bool clearMessage = false,
    DateRange? range,
    bool clearRange = false,
    bool? showVoided,
  }) {
    return OrderHistoryState(
      orders: orders ?? this.orders,
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
      range: clearRange ? null : (range ?? this.range),
      showVoided: showVoided ?? this.showVoided,
    );
  }

  @override
  List<Object?> get props => [orders, status, message, range, showVoided];
}
