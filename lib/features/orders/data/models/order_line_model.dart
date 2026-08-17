import 'package:hive/hive.dart';
import '../../domain/entities/order_line.dart';

part 'order_line_model.g.dart';

@HiveType(typeId: 4)
class OrderLineModel extends OrderLine {
  @override
  @HiveField(0)
  final String productId;
  @override
  @HiveField(1)
  final String itemName;
  @override
  @HiveField(2)
  final String variantLabel;
  @override
  @HiveField(3)
  final double unitPrice;
  @override
  @HiveField(4)
  final int quantity;

  const OrderLineModel({
    required this.productId,
    required this.itemName,
    required this.variantLabel,
    required this.unitPrice,
    required this.quantity,
  }) : super(
          productId: productId,
          itemName: itemName,
          variantLabel: variantLabel,
          unitPrice: unitPrice,
          quantity: quantity,
        );

  factory OrderLineModel.fromEntity(OrderLine line) {
    return OrderLineModel(
      productId: line.productId,
      itemName: line.itemName,
      variantLabel: line.variantLabel,
      unitPrice: line.unitPrice,
      quantity: line.quantity,
    );
  }
}
