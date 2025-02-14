import 'package:hive/hive.dart';

part 'finish_job.g.dart';

@HiveType(typeId: 34)
class FinishJob extends HiveObject {
  @HiveField(0)
  final int taskId;

  @HiveField(1)
  final String installStatus;

  FinishJob({required this.taskId, required this.installStatus});
}
