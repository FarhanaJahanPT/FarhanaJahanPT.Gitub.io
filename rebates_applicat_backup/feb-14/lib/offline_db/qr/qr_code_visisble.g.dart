// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_code_visisble.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QrCodeVisibleAdapter extends TypeAdapter<QrCodeVisible> {
  @override
  final int typeId = 42;

  @override
  QrCodeVisible read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QrCodeVisible(
      worksheetId: fields[0] as int,
      isQrVisible: fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, QrCodeVisible obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.worksheetId)
      ..writeByte(1)
      ..write(obj.isQrVisible);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrCodeVisibleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
