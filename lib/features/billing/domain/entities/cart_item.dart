import 'package:equatable/equatable.dart';
import 'package:cafe_pos/features/product/domain/entities/product.dart';
import 'package:cafe_pos/features/product/domain/entities/product_variant.dart';

class CartItem extends Equatable {
  final Product product;

  /// The chosen size, or null for items that have none.
  final ProductVariant? variant;

  final int quantity;

  const CartItem({
    required this.product,
    this.variant,
    this.quantity = 1,
  });

  double get unitPrice => variant?.price ?? product.price;

  double get total => unitPrice * quantity;

  /// "Latte (Large)" — what the customer sees on the receipt.
  String get displayName =>
      variant == null ? product.name : '${product.name} (${variant!.label})';

  /// Identifies a cart line. A Small and a Large latte are two different
  /// lines, not one line with quantity 2.
  String get lineKey => '${product.id}|${variant?.label ?? ''}';

  CartItem copyWith({
    Product? product,
    ProductVariant? variant,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      variant: variant ?? this.variant,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, variant, quantity];
}
