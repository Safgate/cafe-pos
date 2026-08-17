// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderModelAdapter extends TypeAdapter<OrderModel> {
  @override
  final int typeId = 3;

  @override
  OrderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderModel(
      id: fields[0] as String,
      orderNumber: fields[1] as int,
      createdAt: fields[2] as DateTime,
      lines: (fields[3] as List).cast<OrderLineModel>(),
      total: fields[4] as double,
      createdByStaffId: fields[5] as String,
      createdByStaffName: fields[6] as String,
      updatedAt: fields[7] as DateTime?,
      revision: fields[8] as int,
      lastEditedByStaffId: fields[9] as String,
      lastEditedByStaffName: fields[10] as String,
      voided: fields[11] as bool,
      voidedAt: fields[12] as DateTime?,
      voidedByStaffId: fields[13] as String,
      voidedByStaffName: fields[14] as String,
      voidReason: fields[15] as String,
    );
  }

  @override
  void write(BinaryWriter writer, OrderModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.orderNumber)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.lines)
      ..writeByte(4)
      ..write(obj.total)
      ..writeByte(5)
      ..write(obj.createdByStaffId)
      ..writeByte(6)
      ..write(obj.createdByStaffName)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.revision)
      ..writeByte(9)
      ..write(obj.lastEditedByStaffId)
      ..writeByte(10)
      ..write(obj.lastEditedByStaffName)
      ..writeByte(11)
      ..write(obj.voided)
      ..writeByte(12)
      ..write(obj.voidedAt)
      ..writeByte(13)
      ..write(obj.voidedByStaffId)
      ..writeByte(14)
      ..write(obj.voidedByStaffName)
      ..writeByte(15)
      ..write(obj.voidReason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
