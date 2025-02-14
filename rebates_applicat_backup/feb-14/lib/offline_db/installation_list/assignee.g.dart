// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignee.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssigneeAdapter extends TypeAdapter<Assignee> {
  @override
  final int typeId = 1;

  @override
  Assignee read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Assignee(
      id: fields[0] as int,
      name: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Assignee obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssigneeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
