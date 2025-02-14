// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swms_detail.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SWMSDetailAdapter extends TypeAdapter<SWMSDetail> {
  @override
  final int typeId = 37;

  @override
  SWMSDetail read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SWMSDetail(
      name: fields[0] as String,
      type: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SWMSDetail obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SWMSDetailAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
