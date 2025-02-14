import 'package:hive/hive.dart';

part 'hive_selfie.g.dart';

@HiveType(typeId: 15)
class HiveSelfie extends HiveObject {
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

  HiveSelfie({
    required this.id,
    required this.image,
    required this.selfieType,
    required this.createTime,
    required this.worksheetId,
  });
}

