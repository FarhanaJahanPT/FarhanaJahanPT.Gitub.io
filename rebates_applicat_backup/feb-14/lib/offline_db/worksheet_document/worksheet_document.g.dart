// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worksheet_document.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorksheetDocumentAdapter extends TypeAdapter<WorksheetDocument> {
  @override
  final int typeId = 35;

  @override
  WorksheetDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorksheetDocument(
      premises: fields[0] as String?,
      storeys: fields[1] as String?,
      wallType: fields[2] as String?,
      roofType: fields[3] as String?,
      meterBoxPhase: fields[4] as String?,
      serviceType: fields[5] as String?,
      nmi: fields[6] as String?,
      expectedInverterLocation: fields[7] as String?,
      mountingWallType: fields[8] as String?,
      inverterLocationNotes: fields[9] as String?,
      expectedBatteryLocation: fields[10] as String?,
      mountingType: fields[11] as String?,
      switchBoardUsed: fields[12] as String?,
      installedOrNot: fields[13] as String?,
      description: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WorksheetDocument obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.premises)
      ..writeByte(1)
      ..write(obj.storeys)
      ..writeByte(2)
      ..write(obj.wallType)
      ..writeByte(3)
      ..write(obj.roofType)
      ..writeByte(4)
      ..write(obj.meterBoxPhase)
      ..writeByte(5)
      ..write(obj.serviceType)
      ..writeByte(6)
      ..write(obj.nmi)
      ..writeByte(7)
      ..write(obj.expectedInverterLocation)
      ..writeByte(8)
      ..write(obj.mountingWallType)
      ..writeByte(9)
      ..write(obj.inverterLocationNotes)
      ..writeByte(10)
      ..write(obj.expectedBatteryLocation)
      ..writeByte(11)
      ..write(obj.mountingType)
      ..writeByte(12)
      ..write(obj.switchBoardUsed)
      ..writeByte(13)
      ..write(obj.installedOrNot)
      ..writeByte(14)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorksheetDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
