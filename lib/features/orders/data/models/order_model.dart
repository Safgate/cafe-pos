import 'package:hive/hive.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_line.dart';
import 'order_line_model.dart';

part 'order_model.g.dart';

@HiveType(typeId: 3)
class OrderModel extends Order {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final int orderNumber;
  @override
  @HiveField(2)
  final DateTime createdAt;
  @override
  @HiveField(3)
  final List<OrderLineModel> lines;
  @override
  @HiveField(4)
  final double total;
  @override
  @HiveField(5)
  final String createdByStaffId;
  @override
  @HiveField(6)
  final String createdByStaffName;
  @override
  @HiveField(7)
  final DateTime? updatedAt;
  @override
  @HiveField(8)
  final int revision;
  @override
  @HiveField(9)
  final String lastEditedByStaffId;
  @override
  @HiveField(10)
  final String lastEditedByStaffName;
  @override
  @HiveField(11)
  final bool voided;
  @override
  @HiveField(12)
  final DateTime? voidedAt;
  @override
  @HiveField(13)
  final String voidedByStaffId;
  @override
  @HiveField(14)
  final String voidedByStaffName;
  @override
  @HiveField(15)
  final String voidReason;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    required this.lines,
    required this.total,
    required this.createdByStaffId,
    required this.createdByStaffName,
    required this.updatedAt,
    required this.revision,
    required this.lastEditedByStaffId,
    required this.lastEditedByStaffName,
    required this.voided,
    required this.voidedAt,
    required this.voidedByStaffId,
    required this.voidedByStaffName,
    required this.voidReason,
  }) : super(
          id: id,
          orderNumber: orderNumber,
          createdAt: createdAt,
          lines: lines,
          total: total,
          createdByStaffId: createdByStaffId,
          createdByStaffName: createdByStaffName,
          updatedAt: updatedAt,
          revision: revision,
          lastEditedByStaffId: lastEditedByStaffId,
          lastEditedByStaffName: lastEditedByStaffName,
          voided: voided,
          voidedAt: voidedAt,
          voidedByStaffId: voidedByStaffId,
          voidedByStaffName: voidedByStaffName,
          voidReason: voidReason,
        );

  factory OrderModel.fromEntity(Order order) {
    return OrderModel(
      id: order.id,
      orderNumber: order.orderNumber,
      createdAt: order.createdAt,
      lines: order.lines
          .map((l) => l is OrderLineModel ? l : OrderLineModel.fromEntity(l))
          .toList(),
      total: order.total,
      createdByStaffId: order.createdByStaffId,
      createdByStaffName: order.createdByStaffName,
      updatedAt: order.updatedAt,
      revision: order.revision,
      lastEditedByStaffId: order.lastEditedByStaffId,
      lastEditedByStaffName: order.lastEditedByStaffName,
      voided: order.voided,
      voidedAt: order.voidedAt,
      voidedByStaffId: order.voidedByStaffId,
      voidedByStaffName: order.voidedByStaffName,
      voidReason: order.voidReason,
    );
  }

  Order toEntity() {
    return Order(
      id: id,
      orderNumber: orderNumber,
      createdAt: createdAt,
      lines: List<OrderLine>.from(lines),
      total: total,
      createdByStaffId: createdByStaffId,
      createdByStaffName: createdByStaffName,
      updatedAt: updatedAt,
      revision: revision,
      lastEditedByStaffId: lastEditedByStaffId,
      lastEditedByStaffName: lastEditedByStaffName,
      voided: voided,
      voidedAt: voidedAt,
      voidedByStaffId: voidedByStaffId,
      voidedByStaffName: voidedByStaffName,
      voidReason: voidReason,
    );
  }
}
