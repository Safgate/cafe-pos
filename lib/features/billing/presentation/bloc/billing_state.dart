part of 'billing_bloc.dart';

class BillingState extends Equatable {
  final List<CartItem> cartItems;

  /// Non-null while a past order is being revised.
  final Order? editingOrder;

  /// Set once the order is safely stored — the UI keys its confirmation off
  /// this, not off the print result.
  final Order? completedOrder;

  final bool wasEdit;
  final String? error;
  final bool isSaving;
  final bool isPrinting;

  /// Outcome of the print attempt. Separate from [error] because a failed
  /// print is not a failed sale.
  final String? printMessage;
  final bool printFailed;

  const BillingState({
    this.cartItems = const [],
    this.editingOrder,
    this.completedOrder,
    this.wasEdit = false,
    this.error,
    this.isSaving = false,
    this.isPrinting = false,
    this.printMessage,
    this.printFailed = false,
  });

  double get totalAmount => cartItems.fold(0, (sum, item) => sum + item.total);

  int get itemCount => cartItems.fold(0, (sum, item) => sum + item.quantity);

  bool get isEditing => editingOrder != null;

  bool get isEmpty => cartItems.isEmpty;

  BillingState copyWith({
    List<CartItem>? cartItems,
    Order? editingOrder,
    Order? completedOrder,
    bool? wasEdit,
    String? error,
    bool clearError = false,
    bool? isSaving,
    bool? isPrinting,
    String? printMessage,
    bool clearPrintMessage = false,
    bool? printFailed,
  }) {
    return BillingState(
      cartItems: cartItems ?? this.cartItems,
      editingOrder: editingOrder ?? this.editingOrder,
      completedOrder: completedOrder ?? this.completedOrder,
      wasEdit: wasEdit ?? this.wasEdit,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
      isPrinting: isPrinting ?? this.isPrinting,
      printMessage:
          clearPrintMessage ? null : (printMessage ?? this.printMessage),
      printFailed: printFailed ?? this.printFailed,
    );
  }

  @override
  List<Object?> get props => [
        cartItems,
        editingOrder,
        completedOrder,
        wasEdit,
        error,
        isSaving,
        isPrinting,
        printMessage,
        printFailed,
      ];
}
