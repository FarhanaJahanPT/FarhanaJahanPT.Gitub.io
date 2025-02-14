// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_ccew_document.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectCCEWDocumentAdapter extends TypeAdapter<ProjectCCEWDocument> {
  @override
  final int typeId = 36;

  @override
  ProjectCCEWDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectCCEWDocument(
      documentData: fields[1] as MemoryImage?,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectCCEWDocument obj) {
    writer
      ..writeByte(1)
      ..writeByte(1)
      ..write(obj.documentData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectCCEWDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
