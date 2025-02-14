import 'package:hive/hive.dart';

part 'task_job.g.dart';

@HiveType(typeId: 33)
class TaskJob extends HiveObject {
  @HiveField(0)
  final int taskId;

  @HiveField(1)
  final String date;

  TaskJob({required this.taskId, required this.date});
}
