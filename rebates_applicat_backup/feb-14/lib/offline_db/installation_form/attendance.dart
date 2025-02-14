import 'package:hive/hive.dart';

part 'attendance.g.dart';

@HiveType(typeId: 43)
class Attendance {
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

  Attendance({
    required this.worksheetId,
    required this.latitude,
    required this.longitude,
    required this.date,
    required this.memberId,
  });
}
