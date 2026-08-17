part of 'order_history_bloc.dart';

abstract class OrderHistoryEvent extends Equatable {
  const OrderHistoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadRecentOrders extends OrderHistoryEvent {
  final int limit;
  const LoadRecentOrders({this.limit = 200});
  @override
  List<Object?> get props => [limit];
}

/// Used by the dashboard drill-downs, which hand in an explicit period.
class LoadOrdersInRange extends OrderHistoryEvent {
  final DateRange range;
  const LoadOrdersInRange(this.range);
  @override
  List<Object?> get props => [range];
}

class VoidOrderRequested extends OrderHistoryEvent {
  final String orderId;
  final String reason;
  const VoidOrderRequested({required this.orderId, required this.reason});
  @override
  List<Object?> get props => [orderId, reason];
}

class ToggleShowVoided extends OrderHistoryEvent {}
