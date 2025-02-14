// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_document.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectDocumentsAdapter extends TypeAdapter<ProjectDocuments> {
  @override
  final int typeId = 11;

  @override
  ProjectDocuments read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectDocuments(
      derReceipt: fields[0] as Uint8List?,
      ccewDoc: fields[1] as Uint8List?,
      stcDoc: fields[2] as Uint8List?,
      solarPanelDoc: fields[3] as Uint8List?,
      switchBoardDoc: fields[4] as Uint8List?,
      inverterLocationDoc: fields[5] as Uint8List?,
      batteryLocationDoc: fields[6] as Uint8List?,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectDocuments obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.derReceipt)
      ..writeByte(1)
      ..write(obj.ccewDoc)
      ..writeByte(2)
      ..write(obj.stcDoc)
      ..writeByte(3)
      ..write(obj.solarPanelDoc)
      ..writeByte(4)
      ..write(obj.switchBoardDoc)
      ..writeByte(5)
      ..write(obj.inverterLocationDoc)
      ..writeByte(6)
      ..write(obj.batteryLocationDoc);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectDocumentsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
