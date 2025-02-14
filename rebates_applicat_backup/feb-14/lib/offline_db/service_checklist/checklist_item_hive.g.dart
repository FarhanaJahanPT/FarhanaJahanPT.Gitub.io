// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_item_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ServiceChecklistItemHiveAdapter
    extends TypeAdapter<ServiceChecklistItemHive> {
  @override
  final int typeId = 29;

  @override
  ServiceChecklistItemHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceChecklistItemHive(
      title: fields[0] as String,
      key: fields[1] as String,
      isMandatory: fields[2] as bool,
      uploadedImagePaths: (fields[3] as List).cast<String>(),
      requiredImages: fields[4] as int,
      textContent: fields[5] as String?,
      type: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ServiceChecklistItemHive obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.key)
      ..writeByte(2)
      ..write(obj.isMandatory)
      ..writeByte(3)
      ..write(obj.uploadedImagePaths)
      ..writeByte(4)
      ..write(obj.requiredImages)
      ..writeByte(5)
      ..write(obj.textContent)
      ..writeByte(6)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceChecklistItemHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
