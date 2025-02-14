// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installer_signature_edit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SignatureDataAdapter extends TypeAdapter<SignatureData> {
  @override
  final int typeId = 16;

  @override
  SignatureData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SignatureData(
      id: fields[0] as int,
      installSignature: fields[1] as Uint8List,
      witnessSignature: fields[2] as Uint8List,
      name: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SignatureData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.installSignature)
      ..writeByte(2)
      ..write(obj.witnessSignature)
      ..writeByte(3)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignatureDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
