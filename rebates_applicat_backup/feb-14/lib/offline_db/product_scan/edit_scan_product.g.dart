// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_scan_product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EditScanProductAdapter extends TypeAdapter<EditScanProduct> {
  @override
  final int typeId = 26;

  @override
  EditScanProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EditScanProduct(
      barcode: fields[0] as String,
      imageData: fields[1] as Uint8List?,
      worksheetId: fields[2] as int,
      type: fields[3] as String,
      timestamp: fields[4] as String,
      position: (fields[5] as Map?)?.cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, EditScanProduct obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.barcode)
      ..writeByte(1)
      ..write(obj.imageData)
      ..writeByte(2)
      ..write(obj.worksheetId)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.position);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditScanProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
