// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_item_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChecklistItemHiveAdapter extends TypeAdapter<ChecklistItemHive> {
  @override
  final int typeId = 18;

  @override
  ChecklistItemHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChecklistItemHive(
      title: fields[0] as String,
      key: fields[1] as String,
      isMandatory: fields[2] as bool,
      uploadedImagePaths: (fields[3] as List).cast<String>(),
      requiredImages: fields[4] as int,
      textContent: fields[5] as String?,
      type: fields[6] as String,
      isUpload: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ChecklistItemHive obj) {
    writer
      ..writeByte(8)
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
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.isUpload);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistItemHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
