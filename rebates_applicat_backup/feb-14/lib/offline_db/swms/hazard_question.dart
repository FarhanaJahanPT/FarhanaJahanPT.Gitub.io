import 'package:hive/hive.dart';

part 'hazard_question.g.dart';

@HiveType(typeId: 38)
class HazardQuestion extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String job_activity;

  @HiveField(2)
  final String installationQuestion;

  @HiveField(3)
  final String riskControl;

  @HiveField(4)
  final int categoryId;

  HazardQuestion({
    required this.id,
    required this.job_activity,
    required this.installationQuestion,
    required this.riskControl,
    required this.categoryId,
  });
}
