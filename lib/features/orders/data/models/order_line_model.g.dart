// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_line_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderLineModelAdapter extends TypeAdapter<OrderLineModel> {
  @override
  final int typeId = 4;

  @override
  OrderLineModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderLineModel(
      productId: fields[0] as String,
      itemName: fields[1] as String,
      variantLabel: fields[2] as String,
      unitPrice: fields[3] as double,
      quantity: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, OrderLineModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.itemName)
      ..writeByte(2)
      ..write(obj.variantLabel)
      ..writeByte(3)
      ..write(obj.unitPrice)
      ..writeByte(4)
      ..write(obj.quantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderLineModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
