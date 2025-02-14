import 'package:hive/hive.dart';

part 'swms_detail.g.dart';

@HiveType(typeId: 37)
class SWMSDetail {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String type;

  SWMSDetail({required this.name, required this.type});
}
