import 'package:hive/hive.dart';

part 'service_selfie_edit.g.dart';

@HiveType(typeId: 31)
class ServiceHiveImage {
  @HiveField(0)
  final String checklistType;

  @HiveField(1)
  final String base64Image;

  @HiveField(2)
  final int projectId;

  @HiveField(3)
  final List<dynamic> categIdList;

  @HiveField(4)
  final Map<String, double>? position;

  @HiveField(5)
  final DateTime timestamp;

  ServiceHiveImage({
    required this.checklistType,
    required this.base64Image,
    required this.projectId,
    required this.categIdList,
    this.position,
    required this.timestamp,
  });
}
