// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_checklist.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineChecklistItemAdapter extends TypeAdapter<OfflineChecklistItem> {
  @override
  final int typeId = 19;

  @override
  OfflineChecklistItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineChecklistItem(
      userId: fields[0] as int,
      worksheetId: fields[1] as String,
      checklistId: fields[2] as String,
      title: fields[3] as String,
      isMandatory: fields[4] as bool,
      type: fields[5] as String,
      requiredImages: fields[6] as int,
      uploadedImages: (fields[7] as List).cast<String>(),
      textContent: fields[8] as String?,
      imageBase64: (fields[9] as List).cast<String>(),
      position: (fields[10] as Map?)?.cast<String, double>(),
      createTime: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineChecklistItem obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.worksheetId)
      ..writeByte(2)
      ..write(obj.checklistId)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.isMandatory)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.requiredImages)
      ..writeByte(7)
      ..write(obj.uploadedImages)
      ..writeByte(8)
      ..write(obj.textContent)
      ..writeByte(9)
      ..write(obj.imageBase64)
      ..writeByte(10)
      ..write(obj.position)
      ..writeByte(11)
      ..write(obj.createTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineChecklistItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
