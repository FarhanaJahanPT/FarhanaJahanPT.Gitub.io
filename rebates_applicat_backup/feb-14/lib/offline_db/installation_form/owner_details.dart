import 'package:hive/hive.dart';

part 'owner_details.g.dart';

@HiveType(typeId: 27)
class Partner extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String companyType;

  @HiveField(3)
  final String phone;

  @HiveField(4)
  final String email;

  Partner({required this.id, required this.name, required this.companyType, required this.phone, required this.email});
}
