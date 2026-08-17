import 'package:equatable/equatable.dart';

/// One line of a completed order.
///
/// Everything here is a **snapshot taken at the time of sale** — the item's
/// name and the price actually charged. It deliberately does not reference the
/// live menu item. If it did, raising a coffee's price next month would
/// silently rewrite last month's revenue.
class OrderLine extends Equatable {
  /// Kept only so reports can group sales by item. Never read for price.
  final String productId;

  final String itemName;

  /// The size sold, or '' when the item has no sizes.
  final String variantLabel;

  final double unitPrice;
  final int quantity;

  const OrderLine({
    required this.productId,
    required this.itemName,
    this.variantLabel = '',
    required this.unitPrice,
    required this.quantity,
  });

  double get lineTotal => unitPrice * quantity;

  /// "Latte (Large)"
  String get displayName =>
      variantLabel.isEmpty ? itemName : '$itemName ($variantLabel)';

  /// Groups a size as its own row in reports — a Large latte and a Small
  /// latte are different products commercially.
  String get reportKey => '$productId|$variantLabel';

  OrderLine copyWith({int? quantity}) {
    return OrderLine(
      productId: productId,
      itemName: itemName,
      variantLabel: variantLabel,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props =>
      [productId, itemName, variantLabel, unitPrice, quantity];
}
