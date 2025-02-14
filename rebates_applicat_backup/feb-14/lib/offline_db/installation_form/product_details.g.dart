// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_details.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductDetailAdapter extends TypeAdapter<ProductDetail> {
  @override
  final int typeId = 9;

  @override
  ProductDetail read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductDetail(
      id: fields[0] as String,
      quantity: fields[1] as String,
      model: fields[2] as String,
      manufacturer: fields[3] as String,
      image: fields[4] as String,
      state: fields[5] as String,
      type: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ProductDetail obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.model)
      ..writeByte(3)
      ..write(obj.manufacturer)
      ..writeByte(4)
      ..write(obj.image)
      ..writeByte(5)
      ..write(obj.state)
      ..writeByte(6)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductDetailAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoryDetailAdapter extends TypeAdapter<CategoryDetail> {
  @override
  final int typeId = 10;

  @override
  CategoryDetail read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryDetail(
      id: fields[0] as int,
      name: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryDetail obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryDetailAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
