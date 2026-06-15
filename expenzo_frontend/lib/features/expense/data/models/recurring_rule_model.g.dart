// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rule_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringRuleModelAdapter extends TypeAdapter<RecurringRuleModel> {
  @override
  final int typeId = 2;

  @override
  RecurringRuleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringRuleModel(
      id: fields[0] as String,
      descriptionPattern: fields[1] as String,
      amount: fields[2] as double,
      category: fields[3] as String,
      frequency: fields[4] as String,
      isActive: fields[5] as bool,
      lastUpdated: fields[6] as DateTime,
      isDeleted: fields[7] as bool,
      isSynced: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringRuleModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.descriptionPattern)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.frequency)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.lastUpdated)
      ..writeByte(7)
      ..write(obj.isDeleted)
      ..writeByte(8)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringRuleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
