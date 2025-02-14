// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_signature.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OwnerSignatureHiveAdapter extends TypeAdapter<OwnerSignatureHive> {
  @override
  final int typeId = 8;

  @override
  OwnerSignatureHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OwnerSignatureHive(
      ownerName: fields[0] as String?,
      customerDate: fields[1] as DateTime?,
      ownerSignatureImageBytes: fields[2] as Uint8List?,
    );
  }

  @override
  void write(BinaryWriter writer, OwnerSignatureHive obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.ownerName)
      ..writeByte(1)
      ..write(obj.customerDate)
      ..writeByte(2)
      ..write(obj.ownerSignatureImageBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OwnerSignatureHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
