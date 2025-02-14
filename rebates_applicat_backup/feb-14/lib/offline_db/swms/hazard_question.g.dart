// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hazard_question.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HazardQuestionAdapter extends TypeAdapter<HazardQuestion> {
  @override
  final int typeId = 38;

  @override
  HazardQuestion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HazardQuestion(
      id: fields[0] as int,
      job_activity: fields[1] as String,
      installationQuestion: fields[2] as String,
      riskControl: fields[3] as String,
      categoryId: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HazardQuestion obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.job_activity)
      ..writeByte(2)
      ..write(obj.installationQuestion)
      ..writeByte(3)
      ..write(obj.riskControl)
      ..writeByte(4)
      ..write(obj.categoryId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HazardQuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
