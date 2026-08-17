// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityLogModelAdapter extends TypeAdapter<ActivityLogModel> {
  @override
  final int typeId = 7;

  @override
  ActivityLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityLogModel(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      staffId: fields[2] as String,
      staffName: fields[3] as String,
      action: fields[4] as String,
      entityType: fields[5] as String,
      entityId: fields[6] as String,
      summary: fields[7] as String,
      details: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityLogModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.staffId)
      ..writeByte(3)
      ..write(obj.staffName)
      ..writeByte(4)
      ..write(obj.action)
      ..writeByte(5)
      ..write(obj.entityType)
      ..writeByte(6)
      ..write(obj.entityId)
      ..writeByte(7)
      ..write(obj.summary)
      ..writeByte(8)
      ..write(obj.details);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
