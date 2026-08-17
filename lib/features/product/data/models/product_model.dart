import 'package:hive/hive.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_variant.dart';
import 'product_variant_model.dart';

part 'product_model.g.dart'; // Hive generator

// Field index 2 previously held `barcode` and is retired. Do not reuse it.
@HiveType(typeId: 0)
class ProductModel extends Product {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String name;
  @override
  @HiveField(3)
  final double price;
  @override
  @HiveField(4)
  final int stock;
  @override
  @HiveField(5)
  final String category;
  @override
  @HiveField(6)
  final List<ProductVariantModel> variants;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    required this.variants,
  }) : super(
          id: id,
          name: name,
          price: price,
          stock: stock,
          category: category,
          variants: variants,
        );

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      price: product.price,
      stock: product.stock,
      category: product.category,
      variants: product.variants
          .map((v) => v is ProductVariantModel
              ? v
              : ProductVariantModel.fromEntity(v))
          .toList(),
    );
  }

  Product toEntity() {
    return Product(
      id: id,
      name: name,
      price: price,
      stock: stock,
      category: category,
      variants: List<ProductVariant>.from(variants),
    );
  }
}
