// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_sacn.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedProductAdapter extends TypeAdapter<CachedProduct> {
  @override
  final int typeId = 24;

  @override
  CachedProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedProduct(
      image: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      defaultCode: fields[3] as String,
      qtyProduct: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CachedProduct obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.image)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.defaultCode)
      ..writeByte(4)
      ..write(obj.qtyProduct);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedScannedProductAdapter extends TypeAdapter<CachedScannedProduct> {
  @override
  final int typeId = 28;

  @override
  CachedScannedProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedScannedProduct(
      serialNumber: fields[0] as String,
      name: fields[1] as String,
      unitPrice: fields[2] as String,
      state: fields[3] as String,
      imageData: (fields[4] as List?)?.cast<int>(),
      quantity: fields[5] as int,
      productId: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CachedScannedProduct obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.serialNumber)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.unitPrice)
      ..writeByte(3)
      ..write(obj.state)
      ..writeByte(4)
      ..write(obj.imageData)
      ..writeByte(5)
      ..write(obj.quantity)
      ..writeByte(6)
      ..write(obj.productId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedScannedProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
