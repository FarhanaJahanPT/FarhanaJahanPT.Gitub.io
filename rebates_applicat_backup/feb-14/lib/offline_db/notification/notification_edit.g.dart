// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_edit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationEditAdapter extends TypeAdapter<NotificationEdit> {
  @override
  final int typeId = 21;

  @override
  NotificationEdit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationEdit(
      id: fields[0] as int,
      isRead: fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationEdit obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.isRead);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationEditAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
