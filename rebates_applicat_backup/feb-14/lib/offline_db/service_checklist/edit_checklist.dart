import 'package:hive/hive.dart';

part 'edit_checklist.g.dart'; // Ensure this file is correctly generated.

@HiveType(typeId: 30)
class OfflineServiceChecklistItem extends HiveObject {
  @HiveField(0)
  late int userId;

  @HiveField(1)
  late String worksheetId;

  @HiveField(2)
  late String checklistId;

  @HiveField(3)
  late String title; // Add title field

  @HiveField(4)
  late bool isMandatory; // Add isMandatory field

  @HiveField(5)
  late String type; // Add type field

  @HiveField(6)
  late int requiredImages;

  @HiveField(7)
  List<String> uploadedImages = [];

  @HiveField(8)
  String? textContent;

  @HiveField(9)
  List<String> imageBase64 = [];

  @HiveField(10)
  final Map<String, double>? position;

  @HiveField(11)
  final DateTime createTime;

  // Constructor
  OfflineServiceChecklistItem({
    required this.userId,
    required this.worksheetId,
    required this.checklistId,
    required this.title,
    required this.isMandatory,
    required this.type,
    required this.requiredImages,
    required this.uploadedImages,
    this.textContent,
    required this.imageBase64,
    this.position,
    required this.createTime
  });

  @override
  String toString() {
    return 'OfflineServiceChecklistItem(userId: $userId, worksheetId: $worksheetId, checklistId: $checklistId, title: $title, isMandatory: $isMandatory, type: $type, requiredImages: $requiredImages, uploadedImages: $uploadedImages, textContent: $textContent, imageBase64: $imageBase64, createTime: $createTime)';
  }
}
