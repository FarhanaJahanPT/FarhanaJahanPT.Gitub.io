// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installer_signature.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InstallerSignatureAdapter extends TypeAdapter<InstallerSignature> {
  @override
  final int typeId = 6;

  @override
  InstallerSignature read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstallerSignature(
      installerName: fields[0] as String?,
      witnessName: fields[1] as String?,
      installerDate: fields[2] as DateTime?,
      installerSignatureImageBytes: fields[3] as Uint8List?,
    );
  }

  @override
  void write(BinaryWriter writer, InstallerSignature obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.installerName)
      ..writeByte(1)
      ..write(obj.witnessName)
      ..writeByte(2)
      ..write(obj.installerDate)
      ..writeByte(3)
      ..write(obj.installerSignatureImageBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallerSignatureAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
