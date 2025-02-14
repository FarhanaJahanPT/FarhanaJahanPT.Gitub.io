import 'package:hive/hive.dart';

part 'profile.g.dart';

@HiveType(typeId: 2)
class User {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String phone;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String state;

  // @HiveField(4)
  // final String signupExpiration;

  @HiveField(4)
  final List<Map<String, dynamic>>? userLicenseDetails;

  @HiveField(5)
  final String contactAddressComplete;

  @HiveField(6)
  final String imageBase64;

  User({
    required this.name,
    required this.phone,
    required this.email,
    required this.state,
    // required this.signupExpiration,
    required this.userLicenseDetails,
    required this.contactAddressComplete,
    required this.imageBase64,
  });
}
