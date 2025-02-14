// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_job.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskJobAdapter extends TypeAdapter<TaskJob> {
  @override
  final int typeId = 33;

  @override
  TaskJob read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskJob(
      taskId: fields[0] as int,
      date: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TaskJob obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.taskId)
      ..writeByte(1)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskJobAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
