import 'package:hive/hive.dart';

part 'safety_items.g.dart';

@HiveType(typeId: 40)
class SafetyItems {
  @HiveField(0)
  late int worksheetId;

  @HiveField(1)
  late Map<String, dynamic> fieldValues;

  SafetyItems({required this.worksheetId, required this.fieldValues});
}
