// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hazard_response.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HazardResponseAdapter extends TypeAdapter<HazardResponse> {
  @override
  final int typeId = 41;

  @override
  HazardResponse read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HazardResponse(
      installationQuestionId: fields[0] as int,
      teamMemberInput: fields[1] as String,
      worksheetId: fields[2] as int,
      memberId: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HazardResponse obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.installationQuestionId)
      ..writeByte(1)
      ..write(obj.teamMemberInput)
      ..writeByte(2)
      ..write(obj.worksheetId)
      ..writeByte(3)
      ..write(obj.memberId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HazardResponseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
