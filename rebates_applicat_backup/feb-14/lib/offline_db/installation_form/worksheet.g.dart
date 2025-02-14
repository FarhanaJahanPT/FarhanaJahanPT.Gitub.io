// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worksheet.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorksheetAdapter extends TypeAdapter<Worksheet> {
  @override
  final int typeId = 13;

  @override
  Worksheet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Worksheet(
      id: fields[0] as int?,
      panelCount: fields[1] as int?,
      inverterCount: fields[2] as int?,
      batteryCount: fields[3] as int?,
      checklistCount: fields[4] as int?,
      scannedPanelCount: fields[5] as int?,
      scannedInverterCount: fields[6] as int?,
      scannedBatteryCount: fields[7] as int?,
      checklistCurrentCount: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Worksheet obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.panelCount)
      ..writeByte(2)
      ..write(obj.inverterCount)
      ..writeByte(3)
      ..write(obj.batteryCount)
      ..writeByte(4)
      ..write(obj.checklistCount)
      ..writeByte(5)
      ..write(obj.scannedPanelCount)
      ..writeByte(6)
      ..write(obj.scannedInverterCount)
      ..writeByte(7)
      ..write(obj.scannedBatteryCount)
      ..writeByte(8)
      ..write(obj.checklistCurrentCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorksheetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
