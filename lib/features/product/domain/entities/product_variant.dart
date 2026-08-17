import 'package:equatable/equatable.dart';

/// An optional size for a menu item — "Small", "Large", "12oz".
///
/// A latte has several; a croissant has none. When a [Product] has no variants
/// it sells at its flat price.
class ProductVariant extends Equatable {
  final String label;
  final double price;

  const ProductVariant({
    required this.label,
    required this.price,
  });

  ProductVariant copyWith({String? label, double? price}) {
    return ProductVariant(
      label: label ?? this.label,
      price: price ?? this.price,
    );
  }

  @override
  List<Object?> get props => [label, price];
}
