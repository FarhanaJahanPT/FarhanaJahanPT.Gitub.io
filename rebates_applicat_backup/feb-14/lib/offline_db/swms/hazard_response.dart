import 'package:hive/hive.dart';

part 'hazard_response.g.dart';

@HiveType(typeId: 41)
class HazardResponse {
  @HiveField(0)
  final int installationQuestionId;

  @HiveField(1)
  final String teamMemberInput;

  @HiveField(2)
  final int worksheetId;

  @HiveField(3)
  final int memberId;

  HazardResponse({
    required this.installationQuestionId,
    required this.teamMemberInput,
    required this.worksheetId,
    required this.memberId,
  });
}
