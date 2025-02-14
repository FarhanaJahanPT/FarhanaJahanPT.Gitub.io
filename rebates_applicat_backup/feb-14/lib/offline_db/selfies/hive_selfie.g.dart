// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_selfie.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveSelfieAdapter extends TypeAdapter<HiveSelfie> {
  @override
  final int typeId = 15;

  @override
  HiveSelfie read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSelfie(
      id: fields[0] as int,
      image: fields[1] as String,
      selfieType: fields[2] as String,
      createTime: fields[3] as DateTime,
      worksheetId: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HiveSelfie obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.image)
      ..writeByte(2)
      ..write(obj.selfieType)
      ..writeByte(3)
      ..write(obj.createTime)
      ..writeByte(4)
      ..write(obj.worksheetId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSelfieAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
