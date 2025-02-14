// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_signature_edit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OwnerSignatureEditDataAdapter
    extends TypeAdapter<OwnerSignatureEditData> {
  @override
  final int typeId = 22;

  @override
  OwnerSignatureEditData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OwnerSignatureEditData(
      id: fields[0] as int,
      ownerSignature: fields[1] as Uint8List,
      name: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, OwnerSignatureEditData obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ownerSignature)
      ..writeByte(3)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OwnerSignatureEditDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
