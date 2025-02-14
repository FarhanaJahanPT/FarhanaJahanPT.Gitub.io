// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installing_job.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InstallingJobAdapter extends TypeAdapter<InstallingJob> {
  @override
  final int typeId = 0;

  @override
  InstallingJob read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstallingJob(
      id: fields[0] as int,
      worksheetId: fields[1] as int,
      x_studio_site_address_1: fields[2] as String?,
      date_assign: fields[3] as String?,
      user_name: fields[4] as String?,
      user_ids: (fields[5] as List?)?.cast<int>(),
      project_id: fields[6] as String?,
      install_status: fields[7] as String?,
      name: fields[8] as String?,
      partnerPhone: fields[9] as String?,
      partner_email: fields[10] as String?,
      scannedBarcodeCount: fields[11] as int,
      checklist_current_count: fields[12] as int,
      signature_count: fields[13] as int,
      barcodeTotalCount: fields[14] as int,
      checklistTotalCount: fields[15] as int,
      team_member_ids: (fields[16] as List?)?.cast<int>(),
      memberId: (fields[17] as List).cast<dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, InstallingJob obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.worksheetId)
      ..writeByte(2)
      ..write(obj.x_studio_site_address_1)
      ..writeByte(3)
      ..write(obj.date_assign)
      ..writeByte(4)
      ..write(obj.user_name)
      ..writeByte(5)
      ..write(obj.user_ids)
      ..writeByte(6)
      ..write(obj.project_id)
      ..writeByte(7)
      ..write(obj.install_status)
      ..writeByte(8)
      ..write(obj.name)
      ..writeByte(9)
      ..write(obj.partnerPhone)
      ..writeByte(10)
      ..write(obj.partner_email)
      ..writeByte(11)
      ..write(obj.scannedBarcodeCount)
      ..writeByte(12)
      ..write(obj.checklist_current_count)
      ..writeByte(13)
      ..write(obj.signature_count)
      ..writeByte(14)
      ..write(obj.barcodeTotalCount)
      ..writeByte(15)
      ..write(obj.checklistTotalCount)
      ..writeByte(16)
      ..write(obj.team_member_ids)
      ..writeByte(17)
      ..write(obj.memberId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallingJobAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
