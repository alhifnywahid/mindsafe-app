// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain_rule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DomainRuleAdapter extends TypeAdapter<DomainRule> {
  @override
  final int typeId = 2;

  @override
  DomainRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DomainRule(
      id: fields[0] as String,
      pattern: fields[1] as String,
      category: fields[2] as String,
      priority: fields[3] as int,
      isActive: fields[4] as bool,
      isRegex: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DomainRule obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.pattern)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.priority)
      ..writeByte(4)
      ..write(obj.isActive)
      ..writeByte(5)
      ..write(obj.isRegex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DomainRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
