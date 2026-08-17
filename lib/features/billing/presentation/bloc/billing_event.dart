part of 'billing_bloc.dart';

abstract class BillingEvent extends Equatable {
  const BillingEvent();
  @override
  List<Object?> get props => [];
}

/// Shop details needed to lay out a receipt. Shared by the events that print.
abstract class _ReceiptDetails {
  String get shopName;
  String get address1;
  String get address2;
  String get phone;
  String get footer;
}

class AddProductToCartEvent extends BillingEvent {
  final Product product;

  /// The chosen size, or null for items without sizes.
  final ProductVariant? variant;

  const AddProductToCartEvent(this.product, {this.variant});

  @override
  List<Object?> get props => [product, variant];
}

class RemoveLineEvent extends BillingEvent {
  final String lineKey;
  const RemoveLineEvent(this.lineKey);
  @override
  List<Object?> get props => [lineKey];
}

class UpdateQuantityEvent extends BillingEvent {
  final String lineKey;
  final int quantity;
  const UpdateQuantityEvent(this.lineKey, this.quantity);
  @override
  List<Object?> get props => [lineKey, quantity];
}

class ClearCartEvent extends BillingEvent {}

/// Loads a past order back into the cart so it can be revised.
class StartEditingOrderEvent extends BillingEvent {
  final Order order;

  /// Today's menu, used to recognise items that still exist. Lines keep the
  /// price they were sold at either way.
  final List<Product> currentProducts;

  const StartEditingOrderEvent({
    required this.order,
    required this.currentProducts,
  });

  @override
  List<Object?> get props => [order, currentProducts];
}

/// Saves the cart as an order — creating a new one, or revising the order
/// currently being edited. Saving always happens before printing.
class CompleteOrderEvent extends BillingEvent implements _ReceiptDetails {
  @override
  final String shopName;
  @override
  final String address1;
  @override
  final String address2;
  @override
  final String phone;
  @override
  final String footer;

  final bool printReceipt;

  const CompleteOrderEvent({
    required this.shopName,
    required this.address1,
    required this.address2,
    required this.phone,
    required this.footer,
    this.printReceipt = true,
  });

  @override
  List<Object?> get props =>
      [shopName, address1, address2, phone, footer, printReceipt];
}

class ReprintReceiptEvent extends BillingEvent implements _ReceiptDetails {
  final Order order;

  @override
  final String shopName;
  @override
  final String address1;
  @override
  final String address2;
  @override
  final String phone;
  @override
  final String footer;

  const ReprintReceiptEvent({
    required this.order,
    required this.shopName,
    required this.address1,
    required this.address2,
    required this.phone,
    required this.footer,
  });

  @override
  List<Object?> get props =>
      [order, shopName, address1, address2, phone, footer];
}

/// Clears the completed-order banner and resets the cart for the next
/// customer.
class AcknowledgeCompletionEvent extends BillingEvent {}
