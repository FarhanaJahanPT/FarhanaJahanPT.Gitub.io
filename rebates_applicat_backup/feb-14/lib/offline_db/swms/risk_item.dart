import 'package:hive/hive.dart';

part 'risk_item.g.dart';

@HiveType(typeId: 39)
class RiskItem extends HiveObject {
  @HiveField(0)
  late int worksheetId;

  @HiveField(1)
  late Map<String, dynamic> fieldValues;

  RiskItem({required this.worksheetId, required this.fieldValues});
}
