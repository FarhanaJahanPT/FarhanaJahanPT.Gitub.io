import 'package:hive/hive.dart';

part 'edit_user.g.dart';

@HiveType(typeId: 3)
class UserModel {
  @HiveField(0)
  String name;

  @HiveField(1)
  String email;

  @HiveField(2)
  String phone;

  @HiveField(3)
  String contactAddress;

  UserModel({required this.name, required this.email, required this.phone, required this.contactAddress});
}
