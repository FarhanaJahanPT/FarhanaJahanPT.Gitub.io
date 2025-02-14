import 'package:hive/hive.dart';

part 'attendance_checkout.g.dart';

@HiveType(typeId: 44)
class AttendanceCheckout {
  @HiveField(0)
  final int worksheetId;

  @HiveField(1)
  double latitude;

  @HiveField(2)
  double longitude;

  @HiveField(3)
  String date;

  @HiveField(4)
  int memberId;

  AttendanceCheckout({
    required this.worksheetId,
    required this.latitude,
    required this.longitude,
    required this.date,
    required this.memberId,
  });
}
