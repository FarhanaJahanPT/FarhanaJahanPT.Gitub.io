import 'package:hive/hive.dart';

part 'installing_job.g.dart';

@HiveType(typeId: 0)
class InstallingJob {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int worksheetId;

  @HiveField(2)
  final String? x_studio_site_address_1;

  @HiveField(3)
  final String? date_assign;

  @HiveField(4)
  final String? user_name;

  @HiveField(5)
  final List<int>? user_ids;

  @HiveField(6)
  final String? project_id;

  @HiveField(7)
  final String? install_status;

  @HiveField(8)
  final String? name;

  @HiveField(9)
  final String? partnerPhone;

  @HiveField(10)
  final String? partner_email;

  @HiveField(11)
  final int scannedBarcodeCount;

  @HiveField(12)
  final int checklist_current_count;

  @HiveField(13)
  final int signature_count;

  @HiveField(14)
  final int barcodeTotalCount;

  @HiveField(15)
  final int checklistTotalCount;

  @HiveField(16)
  final List<int>? team_member_ids;

  @HiveField(17)
  final List<dynamic> memberId;

  InstallingJob({
    required this.id,
    required this.worksheetId,
    this.x_studio_site_address_1,
    this.date_assign,
    this.user_name,
    this.user_ids,
    this.project_id,
    this.install_status,
    this.name,
    this.partnerPhone,
    this.partner_email,
    required this.scannedBarcodeCount,
    required this.checklist_current_count,
    required this.signature_count,
    required this.barcodeTotalCount,
    required this.checklistTotalCount,
    this.team_member_ids,
    required this.memberId
  });

  InstallingJob copyWith({
    String? install_status,
    int? scannedBarcodeCount,
    int? checklist_current_count,
    int? signature_count,
  }) {
    return InstallingJob(
      id: id,
      x_studio_site_address_1: x_studio_site_address_1,
      date_assign: date_assign,
      user_name: user_name,
      user_ids: user_ids,
      project_id: project_id,
      install_status: install_status ?? this.install_status,
      name: name,
      partnerPhone: partnerPhone,
      partner_email: partner_email,
      scannedBarcodeCount: scannedBarcodeCount ?? this.scannedBarcodeCount,
      checklist_current_count:
          checklist_current_count ?? this.checklist_current_count,
      signature_count: signature_count ?? this.signature_count,
      barcodeTotalCount: barcodeTotalCount,
      checklistTotalCount: checklistTotalCount,
      worksheetId: this.worksheetId,
      memberId: this.memberId,
      team_member_ids: team_member_ids ?? this.team_member_ids,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worksheetId': worksheetId,
      'memberId': memberId,
      'x_studio_site_address_1': x_studio_site_address_1,
      'date_assign': date_assign,
      'user_name': user_name,
      'user_ids': user_ids,
      'projectId': project_id,
      'install_status': install_status,
      'name': name,
      'partnerPhone': partnerPhone,
      'partnerEmail': partner_email,
      'scannedBarcodeCount': scannedBarcodeCount,
      'checklist_current_count': checklist_current_count,
      'signature_count': signature_count,
      'barcodeTotalCount': barcodeTotalCount,
      'checklistTotalCount': checklistTotalCount,
      'team_member_ids': team_member_ids
    };
  }
}
