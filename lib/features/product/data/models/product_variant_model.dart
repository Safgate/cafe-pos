import 'package:hive/hive.dart';
import '../../domain/entities/product_variant.dart';

part 'product_variant_model.g.dart';

@HiveType(typeId: 2)
class ProductVariantModel extends ProductVariant {
  @override
  @HiveField(0)
  final String label;
  @override
  @HiveField(1)
  final double price;

  const ProductVariantModel({
    required this.label,
    required this.price,
  }) : super(label: label, price: price);

  factory ProductVariantModel.fromEntity(ProductVariant variant) {
    return ProductVariantModel(
      label: variant.label,
      price: variant.price,
    );
  }
}
