// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_checkout.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceCheckoutAdapter extends TypeAdapter<AttendanceCheckout> {
  @override
  final int typeId = 44;

  @override
  AttendanceCheckout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceCheckout(
      worksheetId: fields[0] as int,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      date: fields[3] as String,
      memberId: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceCheckout obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.worksheetId)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.memberId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceCheckoutAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
