// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selfie_edit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveImageAdapter extends TypeAdapter<HiveImage> {
  @override
  final int typeId = 14;

  @override
  HiveImage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveImage(
      checklistType: fields[0] as String,
      base64Image: fields[1] as String,
      projectId: fields[2] as int,
      categIdList: (fields[3] as List).cast<dynamic>(),
      position: (fields[4] as Map?)?.cast<String, double>(),
      timestamp: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HiveImage obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.checklistType)
      ..writeByte(1)
      ..write(obj.base64Image)
      ..writeByte(2)
      ..write(obj.projectId)
      ..writeByte(3)
      ..write(obj.categIdList)
      ..writeByte(4)
      ..write(obj.position)
      ..writeByte(5)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveImageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
