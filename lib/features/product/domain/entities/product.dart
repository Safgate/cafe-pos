import 'package:equatable/equatable.dart';
import 'product_variant.dart';

/// A menu item. Named `Product` throughout the code for continuity with the
/// original project; presented to the user as "Menu Item".
class Product extends Equatable {
  final String id;
  final String name;

  /// Free-text grouping shown as a chip on the order screen — "Coffee",
  /// "Pastries", "Cold Drinks". May be empty.
  final String category;

  /// Flat price, used only when [variants] is empty.
  final double price;

  final int stock;

  /// Optional sizes. When non-empty the chosen variant's price wins and
  /// [price] is ignored.
  final List<ProductVariant> variants;

  const Product({
    required this.id,
    required this.name,
    this.category = '',
    required this.price,
    this.stock = 0,
    this.variants = const [],
  });

  bool get hasVariants => variants.isNotEmpty;

  /// Price to show on the menu grid: the cheapest size when the item has
  /// sizes, otherwise the flat price.
  double get displayPrice {
    if (!hasVariants) return price;
    return variants
        .map((v) => v.price)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Price actually charged for a given size. Falls back to the flat price
  /// when no size applies.
  double priceFor(ProductVariant? variant) => variant?.price ?? price;

  @override
  List<Object?> get props => [id, name, category, price, stock, variants];
}
