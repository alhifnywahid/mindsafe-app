// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain_access.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DomainAccessAdapter extends TypeAdapter<DomainAccess> {
  @override
  final int typeId = 0;

  @override
  DomainAccess read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DomainAccess(
      domain: fields[0] as String,
      timestamp: fields[1] as DateTime,
      durationSeconds: fields[2] as int,
      category: fields[3] as String,
      synced: fields[4] as bool,
      userId: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DomainAccess obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.domain)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.durationSeconds)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.synced)
      ..writeByte(5)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DomainAccessAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
