import 'package:hive/hive.dart';

part 'service_hive_selfie.g.dart';

@HiveType(typeId: 32)
class HiveServiceSelfie extends HiveObject {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String image;
  @HiveField(2)
  final String selfieType;
  @HiveField(3)
  final DateTime createTime;
  @HiveField(4)
  final int worksheetId;

  HiveServiceSelfie({
    required this.id,
    required this.image,
    required this.selfieType,
    required this.createTime,
    required this.worksheetId,
  });
}

