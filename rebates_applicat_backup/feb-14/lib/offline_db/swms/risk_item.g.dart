// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'risk_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RiskItemAdapter extends TypeAdapter<RiskItem> {
  @override
  final int typeId = 39;

  @override
  RiskItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RiskItem(
      worksheetId: fields[0] as int,
      fieldValues: (fields[1] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, RiskItem obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.worksheetId)
      ..writeByte(1)
      ..write(obj.fieldValues);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiskItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
