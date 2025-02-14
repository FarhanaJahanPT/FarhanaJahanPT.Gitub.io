// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finish_job.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FinishJobAdapter extends TypeAdapter<FinishJob> {
  @override
  final int typeId = 34;

  @override
  FinishJob read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FinishJob(
      taskId: fields[0] as int,
      installStatus: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FinishJob obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.taskId)
      ..writeByte(1)
      ..write(obj.installStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinishJobAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
