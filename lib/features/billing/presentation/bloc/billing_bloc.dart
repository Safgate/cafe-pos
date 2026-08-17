import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
// fpdart exports an `Order` typeclass that collides with our sale entity.
import 'package:fpdart/fpdart.dart' hide Order;
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';

import 'package:cafe_pos/features/product/domain/entities/product.dart';
import 'package:cafe_pos/features/product/domain/entities/product_variant.dart';

import '../../../../core/data/hive_database.dart';
import '../../../../core/session/current_session.dart';
import '../../../../core/utils/printer_helper.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/entities/order_line.dart';
import '../../../orders/domain/repositories/order_repository.dart';
import '../../domain/entities/cart_item.dart';

part 'billing_event.dart';
part 'billing_state.dart';

class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final OrderRepository orderRepository;
  final PrinterHelper printer;

  BillingBloc({
    required this.orderRepository,
    PrinterHelper? printer,
  })  : printer = printer ?? PrinterHelper(),
        super(const BillingState()) {
    on<AddProductToCartEvent>(_onAddProductToCart);
    on<RemoveLineEvent>(_onRemoveLine);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
    on<ClearCartEvent>(_onClearCart);
    on<StartEditingOrderEvent>(_onStartEditingOrder);
    on<CompleteOrderEvent>(_onCompleteOrder);
    on<ReprintReceiptEvent>(_onReprintReceipt);
    on<AcknowledgeCompletionEvent>(_onAcknowledgeCompletion);
  }

  void _onAddProductToCart(
      AddProductToCartEvent event, Emitter<BillingState> emit) {
    final newItem = CartItem(product: event.product, variant: event.variant);

    // Merge on product + size. A Small and a Large latte are two lines.
    final index =
        state.cartItems.indexWhere((item) => item.lineKey == newItem.lineKey);

    if (index >= 0) {
      final items = List<CartItem>.from(state.cartItems);
      items[index] =
          items[index].copyWith(quantity: items[index].quantity + 1);
      emit(state.copyWith(cartItems: items, clearError: true));
    } else {
      emit(state.copyWith(
        cartItems: [...state.cartItems, newItem],
        clearError: true,
      ));
    }
  }

  void _onRemoveLine(RemoveLineEvent event, Emitter<BillingState> emit) {
    emit(state.copyWith(
      cartItems:
          state.cartItems.where((i) => i.lineKey != event.lineKey).toList(),
    ));
  }

  void _onUpdateQuantity(
      UpdateQuantityEvent event, Emitter<BillingState> emit) {
    if (event.quantity <= 0) {
      add(RemoveLineEvent(event.lineKey));
      return;
    }

    final index =
        state.cartItems.indexWhere((item) => item.lineKey == event.lineKey);
    if (index < 0) return;

    final items = List<CartItem>.from(state.cartItems);
    items[index] = items[index].copyWith(quantity: event.quantity);
    emit(state.copyWith(cartItems: items));
  }

  void _onClearCart(ClearCartEvent event, Emitter<BillingState> emit) {
    emit(const BillingState());
  }

  /// Loads a past order back into the cart for editing.
  ///
  /// Existing lines are rebuilt from the order's own snapshot, so changing a
  /// quantity charges the price the customer originally paid. Anything *added*
  /// during the edit is priced from today's menu.
  void _onStartEditingOrder(
      StartEditingOrderEvent event, Emitter<BillingState> emit) {
    final byId = {for (final p in event.currentProducts) p.id: p};

    final items = event.order.lines.map((line) {
      final live = byId[line.productId];

      // The item may since have been removed from the menu — the order still
      // has to be editable, so rebuild it from what was sold.
      final product = Product(
        id: line.productId,
        name: live?.name ?? line.itemName,
        category: live?.category ?? '',
        price: line.unitPrice,
      );

      final variant = line.variantLabel.isEmpty
          ? null
          : ProductVariant(label: line.variantLabel, price: line.unitPrice);

      return CartItem(
        product: product,
        variant: variant,
        quantity: line.quantity,
      );
    }).toList();

    emit(BillingState(cartItems: items, editingOrder: event.order));
  }

  Future<void> _onCompleteOrder(
      CompleteOrderEvent event, Emitter<BillingState> emit) async {
    if (state.cartItems.isEmpty) {
      emit(state.copyWith(error: 'The order is empty.'));
      return;
    }

    emit(state.copyWith(isSaving: true, clearError: true));

    final lines = state.cartItems
        .map((item) => OrderLine(
              productId: item.product.id,
              itemName: item.product.name,
              variantLabel: item.variant?.label ?? '',
              unitPrice: item.unitPrice,
              quantity: item.quantity,
            ))
        .toList();
    final total = state.totalAmount;

    final editing = state.editingOrder;
    final Order order;
    final Either<Failure, void> result;

    if (editing == null) {
      order = Order(
        id: const Uuid().v4(),
        orderNumber: await orderRepository.nextOrderNumber(),
        createdAt: DateTime.now(),
        lines: lines,
        total: total,
        createdByStaffId: CurrentSession.staffId,
        createdByStaffName: CurrentSession.staffName,
      );
      result = await orderRepository.saveOrder(order);
    } else {
      // The original order number and date are preserved — an edit revises a
      // sale, it does not create a new one.
      order = editing.copyWith(lines: lines, total: total);
      result = await orderRepository.updateOrder(
        before: editing,
        updated: order,
      );
    }

    await result.fold(
      (failure) async => emit(state.copyWith(
        isSaving: false,
        error: 'Could not save the order: ${failure.message}',
      )),
      (_) async {
        emit(state.copyWith(
          isSaving: false,
          completedOrder: order,
          wasEdit: editing != null,
        ));

        // Printing happens *after* the sale is recorded and can never undo
        // it. A dead printer or an empty till roll must not cost the shop a
        // record of its revenue.
        if (event.printReceipt) {
          await _print(emit, order: order, event: event, isReprint: false);
        }
      },
    );
  }

  Future<void> _onReprintReceipt(
      ReprintReceiptEvent event, Emitter<BillingState> emit) async {
    await _print(
      emit,
      order: event.order,
      event: event,
      isReprint: true,
    );
    await orderRepository.logReprint(event.order);
  }

  Future<void> _print(
    Emitter<BillingState> emit, {
    required Order order,
    required _ReceiptDetails event,
    required bool isReprint,
  }) async {
    if (!printer.isConnected) {
      final savedMac = HiveDatabase.settingsBox.get('printer_mac');
      if (savedMac == null || !await printer.connect(savedMac as String)) {
        emit(state.copyWith(
          printMessage: 'Saved, but the printer could not be reached.',
          printFailed: true,
        ));
        return;
      }
    }

    emit(state.copyWith(isPrinting: true, clearPrintMessage: true));

    try {
      await printer.printReceipt(
        shopName: event.shopName,
        address1: event.address1,
        address2: event.address2,
        phone: event.phone,
        footer: event.footer,
        order: order,
        isReprint: isReprint,
      );
      emit(state.copyWith(
        isPrinting: false,
        printMessage: isReprint ? 'Receipt reprinted' : 'Receipt printed',
        printFailed: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isPrinting: false,
        printMessage: 'Saved, but printing failed: $e',
        printFailed: true,
      ));
    }
  }

  void _onAcknowledgeCompletion(
      AcknowledgeCompletionEvent event, Emitter<BillingState> emit) {
    emit(const BillingState());
  }
}
