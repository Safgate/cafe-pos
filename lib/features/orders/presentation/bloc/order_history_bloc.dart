import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/utils/date_range.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

part 'order_history_event.dart';
part 'order_history_state.dart';

class OrderHistoryBloc extends Bloc<OrderHistoryEvent, OrderHistoryState> {
  final OrderRepository repository;

  OrderHistoryBloc({required this.repository})
      : super(const OrderHistoryState()) {
    on<LoadRecentOrders>(_onLoadRecent);
    on<LoadOrdersInRange>(_onLoadRange);
    on<VoidOrderRequested>(_onVoidOrder);
    on<ToggleShowVoided>(_onToggleShowVoided);
  }

  Future<void> _onLoadRecent(
      LoadRecentOrders event, Emitter<OrderHistoryState> emit) async {
    emit(state.copyWith(
        status: OrderHistoryStatus.loading, clearMessage: true));
    final result = await repository.getRecentOrders(limit: event.limit);
    result.fold(
      (failure) => emit(state.copyWith(
          status: OrderHistoryStatus.error, message: failure.message)),
      (orders) => emit(state.copyWith(
          status: OrderHistoryStatus.loaded, orders: orders, clearRange: true)),
    );
  }

  Future<void> _onLoadRange(
      LoadOrdersInRange event, Emitter<OrderHistoryState> emit) async {
    emit(state.copyWith(
        status: OrderHistoryStatus.loading, clearMessage: true));
    final result =
        await repository.getOrdersInRange(event.range.from, event.range.to);
    result.fold(
      (failure) => emit(state.copyWith(
          status: OrderHistoryStatus.error, message: failure.message)),
      (orders) => emit(state.copyWith(
        status: OrderHistoryStatus.loaded,
        orders: orders,
        range: event.range,
      )),
    );
  }

  Future<void> _onVoidOrder(
      VoidOrderRequested event, Emitter<OrderHistoryState> emit) async {
    final result =
        await repository.voidOrder(id: event.orderId, reason: event.reason);
    await result.fold(
      (failure) async => emit(state.copyWith(
          status: OrderHistoryStatus.error, message: failure.message)),
      (_) async {
        emit(state.copyWith(
            status: OrderHistoryStatus.success, message: 'Order voided'));
        // Reload through whichever view is active.
        if (state.range != null) {
          add(LoadOrdersInRange(state.range!));
        } else {
          add(const LoadRecentOrders());
        }
      },
    );
  }

  void _onToggleShowVoided(
      ToggleShowVoided event, Emitter<OrderHistoryState> emit) {
    emit(state.copyWith(showVoided: !state.showVoided));
  }
}
