import 'package:hive/hive.dart';
import 'dart:io';

part 'checklist_item_hive.g.dart';

@HiveType(typeId: 18)
class ChecklistItemHive extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String key;

  @HiveField(2)
  final bool isMandatory;

  @HiveField(3)
  final List<String> uploadedImagePaths;

  @HiveField(4)
  final int requiredImages;

  @HiveField(5)
  final String? textContent;

  @HiveField(6)
  final String type;

  @HiveField(7)
  final bool isUpload;

  ChecklistItemHive({
    required this.title,
    required this.key,
    required this.isMandatory,
    required this.uploadedImagePaths,
    required this.requiredImages,
    this.textContent,
    required this.type,
    required this.isUpload,
  });
}
