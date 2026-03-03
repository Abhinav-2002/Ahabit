// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] is String ? fields[0] as String : '',
      name: fields[1] is String ? fields[1] as String : '',
      icon: fields[2] is String ? fields[2] as String : '📌',
      colorValue: fields[3] is int ? fields[3] as int : 0xFF000000,
      colorIndex: fields[4] is int ? fields[4] as int : 0,
      frequency: fields[5] is String ? fields[5] as String : 'daily',
      createdAt: fields[6] is DateTime ? fields[6] as DateTime : DateTime.now(),
      isHidden: fields[7] is bool ? fields[7] as bool : false,
      sortOrder: fields[8] is int ? fields[8] as int : 0,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.icon)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.colorIndex)
      ..writeByte(5)
      ..write(obj.frequency)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isHidden)
      ..writeByte(8)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
